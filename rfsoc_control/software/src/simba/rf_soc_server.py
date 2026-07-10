"""RFSoC Server and acqusition functions."""

import json
import logging
import os
import queue
import re
import socket
import threading
from time import sleep

from pynq import allocate

import numpy as np
from config_utils import load_lo_config, write_lo_config
from firmware_utils import configure_lockin, load_overlay, read_counters, start_clocks

N_ITER = 10

FW_VERSION = 3  # 3 ADC activated, 4 lockins per group
IP_ADDR = "212.189.204.163"

DATA_DIR = "/bauscia-nas/data/rfsoc_savedir/"


class RFSoCServer:
    """RFSoCServer class shares network, threading and hardware info."""

    def __init__(self, host=IP_ADDR, port=6000, port_data=6001, data_dir=DATA_DIR):
        """Initialize threads and empty attributes.

        Ports and other configuration parameters shouldn't me changed.
        """
        # Network
        self.host = host
        self.port = port
        self.port_data = port_data
        self.data_dir = data_dir

        # Server state
        self.server_state = "idle"

        # Threading info, events, locks
        self.state_lock = threading.Lock()
        self.stop_event = threading.Event()
        self.save_queue = queue.Queue()
        self.reload_event = threading.Event()
        self.reload_done = threading.Event()
        self.acq_thread = None

        # Hardware state
        self.overlay = None
        self.controller = None
        self.lockins = None
        self.sync = None
        self.dmas = None
        self.dma_groups = None
        self.group_size = None

        # Acquisition config
        self.frequencies = []
        self.metadata = {}

    def start_acquisition(self):
        """Start supervisor, function called by client with start cmd.

        While state is fixed, load LOs configs, change the state to running,
        create and start supervisor thread. Return okay status to client.
        """
        logging.info("[SERVER] Starting function")
        with self.state_lock:
            self.stop_event.clear()
            load_lo_config(self, FW_VERSION)
            self.server_state = "running"
            self.acq_thread = threading.Thread(
                target=self._acquisition_loop_supervisor, daemon=True
            )
            self.acq_thread.start()
            return b'{"status":"ok"}'

    def stop_acquisition(self):
        """Stop acquisition, function called by client.

        Assert stop event wich stops acquisition after an iteration.
        Assert reset from hardware control and reset server_state as idle.
        """
        logging.info("[SERVER] Starting function")
        with self.state_lock:
            self.stop_event.set()
            acq_thread = self.acq_thread

        if acq_thread is not None:
            acq_thread.join(timeout=10)
            if acq_thread.is_alive():
                # Forza lo shutdown se il thread non muore
                assert self.controller is not None
                self.controller.reset(self.sync)

        sleep(10)  # Aspetta il cleanup

        with self.state_lock:
            self.server_state = "idle"
        return b'{"status":"ok"}'

    def _acquisition_loop_supervisor(self):
        """Start acqusition loop in a fault-tolerant loop.

        If an exception happens during the acqusition, the supervisor should
        reload the overlay (with self.reload_event.set()) and restart the acquisition.
        """
        logging.info("[SERVER] Starting function")
        retry_count = 0
        max_retries = 5

        while not self.stop_event.is_set():
            try:
                retry_count = 0  # Reset retry count on successful start
                self._acquisition_loop()

            except Exception as e:
                logging.error(f"[ACQ] Error during acquisition: {e}")

                with self.state_lock:
                    current_state = self.server_state

                if current_state == "running" and retry_count < max_retries:
                    retry_count += 1
                    logging.info(f"[ACQ] Restart try {retry_count}/{max_retries}")

                    try:
                        self._hardware_shutdown()
                    except Exception as e:
                        logging.error(f"[ACQ] Error during shutdown: {e}")

                    self.reload_done.clear()
                    self.reload_event.set()
                    self.reload_done.wait(timeout=30)
                    continue  # Return to the while without going idle
                break  # If max_retries reached we break

        self.server_state = (
            "idle"  # If the acq was stopped (by cmd usually) remove all files
        )
        self._remove_all_files()
        logging.info("[ACQ] Supervisor exiting")
        self.reload_event.set()  # If acq was stopped, reload firmware for safety

    def _hardware_shutdown(self):
        """Stop dmas and shutdown RFDC tiles in hope of avoiding hw errors."""
        logging.info("[HW] Shutting down hardware")
        try:
            if self.controller is not None:
                self.controller.reset(self.sync)
        except Exception as e:
            logging.warning(f"[HW] controller reset failed: {e}")

        if self.dmas is not None:
            for dma in self.dmas:
                try:
                    dma.stop()
                except Exception as e:
                    logging.warning(f"[HW] dma stop failed: {e}")

        ov = self.overlay
        assert ov is not None

        for tile in ov.rfdc.adc_tiles:
            try:
                tile.ShutDown()
                logging.info(f"[HW] tile did shutdown")
            except Exception as e:
                logging.warning(f"[HW] tile did not shutdown")

    def _acquisition_loop(self):
        """Allocate buffers, start acq and loop over buffers/dma saving into queue."""
        logging.info("[SERVER] Starting function")
        start_clocks(ext_clk=True)
        bufs, dmas = self._allocate_dma_buffers()
        self.dmas = dmas

        try:
            if self.controller is None:
                raise RuntimeError("Controller not initialized")
            self.controller.reset(self.sync)
            self.controller.config()
            t0 = self.controller.start(self.sync, True)

            buffer_idx = 0
            file_index = 0

            while not self.stop_event.is_set():
                tot_i = [[] for _ in self.frequencies]
                tot_q = [[] for _ in self.frequencies]

                for it in range(N_ITER):
                    # Start DMA into current ping-pong buffer (per group)
                    self._start_dma_transfers(dmas, bufs, buffer_idx)

                    # If this is not the first iteration, the previous buffer
                    # is now safe to read/copy while current DMA is running
                    if it > 0:
                        prev = 1 - buffer_idx
                        for ch in range(len(self.frequencies)):
                            group_idx, lane = divmod(ch, self.group_size)
                            q, i = self._extract_iq(bufs[group_idx][prev], lane)
                            tot_i[ch].append(i.copy())
                            tot_q[ch].append(q.copy())

                    # Wait for current transfers to complete
                    self._wait_dma(dmas)

                    # Swap ping-pong buffer
                    buffer_idx = 1 - buffer_idx

                # Append the final completed buffer
                last = 1 - buffer_idx
                for ch in range(len(self.frequencies)):
                    group_idx, lane = divmod(ch, self.group_size)
                    q, i = self._extract_iq(bufs[group_idx][last], lane)
                    tot_i[ch].append(i)
                    tot_q[ch].append(q)

                self.save_queue.put(
                    (
                        file_index,
                        [np.concatenate(x) for x in tot_i],
                        [np.concatenate(x) for x in tot_q],
                        t0,
                        read_counters(self.overlay),
                    )
                )
                file_index += 1
        finally:
            self._hardware_shutdown()

    def _allocate_dma_buffers(self):
        """Allocate contiguous PYNQ ping-pong buffers, one pair per active group.

        Lock-ins are packed `self.group_size` per 256-bit DMA channel in
        hardware. Since dec_factor is fixed and identical for every lock-in,
        all lanes of a group always produce a new sample in lockstep, so a
        full group must be transferred even if only some of its lanes carry
        a frequency of interest (unused trailing lanes are simply not
        extracted later).
        """
        logging.info("[SERVER] Starting function")
        assert self.lockins is not None
        assert self.dma_groups is not None

        for idx, freq in enumerate(self.frequencies):
            configure_lockin(
                self.lockins[idx], frequency=freq, phase=0, dec_factor=1, fir_dec=468750
            )

        n_groups = (len(self.frequencies) + self.group_size - 1) // self.group_size
        bufs = [
            [allocate(256 * self.group_size, np.uint64) for _ in range(2)]
            for _ in range(n_groups)
        ]
        dmas = self.dma_groups[:n_groups]
        return bufs, dmas

    def _start_dma_transfers(self, dmas, bufs, buffer_idx):
        """Start all dma transfers."""
        for idx, dma in enumerate(dmas):
            dma.transfer(bufs[idx][buffer_idx])

    def _wait_dma(self, dmas):
        """Wait for all dma transfers."""
        for dma in dmas:
            dma.wait()

    def _extract_iq(self, buffer, lane):
        """Extract IQ data (2x32 bit) for one lock-in lane from a group buffer.

        Each group buffer packs `self.group_size` lock-ins per sample (one
        64-bit word per lock-in: {Q[31:0], I[31:0]}). `lane` (0-based)
        selects which lock-in of the group to decode.
        """
        lane_words = buffer.reshape(-1, self.group_size)[:, lane].copy()
        data32 = lane_words.view(np.int32)
        return data32[0::2].copy(), data32[1::2].copy()

    def start_control_server(self):
        """Start server for cmd handling."""
        logging.info("[SERVER] Starting function")
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        sock.bind((self.host, self.port))

        sock.listen(50)

        logging.info(f"[SERVER] listening on {self.port}")

        try:
            while True:
                conn, _ = sock.accept()
                threading.Thread(
                    target=self._handle_client, args=(conn,), daemon=True
                ).start()
        finally:
            sock.close()

    def _handle_client(self, conn):
        """Handle client connection."""
        logging.info("[SERVER] Starting function")
        with conn:
            try:
                msg = json.loads(conn.recv(4096).decode())
                cmd = msg.get("cmd")
            except (json.JSONDecodeError, UnicodeDecodeError, ValueError) as e:
                logging.error(f"[SERVER] Error: {e}")
                conn.sendall(
                    b'{"status":"error", "msg":"Communication error, try again"}'
                )
                return

            conn.sendall(self._handle_command(cmd, msg))

    def _handle_command(self, cmd, msg):
        """Handle command request."""
        logging.info("[SERVER] Starting function")
        if cmd == "state_info":
            logging.info(f"[SERVER] Requested status, was {self.server_state}")
            return self.server_state.encode()
        if cmd == "start" and self.server_state == "idle":
            logging.info("[SERVER] Starting acquisition.")
            return self.start_acquisition()
        if cmd == "stop" and self.server_state == "running":
            logging.info("[SERVER] Stopping acquisition.")
            return self.stop_acquisition()
        if cmd == "config_lo" and self.server_state == "idle":
            logging.info("[SERVER] Configuring lockins.")
            write_lo_config(msg["config"])
            return b'{"status":"ok"}'
        if cmd == "remove_files" and self.server_state == "idle":
            logging.info("[SERVER] Removing files.")
            self._remove_all_files()
            return b'{"status":"ok"}'
        logging.warning(
            f"[SERVER] Received invalid command of {cmd} in state {self.server_state}"
        )
        return b'{"status": "error", "msg": "Invalid command or state"}'

    def start_data_server(self):
        """Start server for data download."""
        logging.info("[SERVER] Starting function")
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        sock.bind((self.host, self.port_data))
        sock.listen(1)

        logging.info(f"[DATA] listening on {self.port_data}")

        try:
            while True:
                conn, addr = sock.accept()
                threading.Thread(
                    target=self._handle_data_client, args=(conn, addr), daemon=True
                ).start()
        except KeyboardInterrupt:
            logging.info("[DATA] interrupted")
        finally:
            sock.close()
            logging.info("[DATA] socket closed")

    def _handle_data_client(self, conn, addr):
        """Handle client for data download."""
        logging.info(f"[DATA] Connected {addr}")
        files_by_number = self._group_files()
        numbers = sorted(files_by_number.keys())
        if len(numbers) <= 1:
            conn.sendall((0).to_bytes(4, "big"))
            return
        for num in numbers[:-1]:
            for fname in sorted(files_by_number[num]):
                self._send_file(conn, fname)
        conn.sendall((0).to_bytes(4, "big"))
        conn.close()

    def _group_files(self):
        """Group files by number."""
        logging.info("[SERVER] Starting function")
        pattern = re.compile(r"_(\d+)\.")
        files_by_number = {}
        for fname in os.listdir(self.data_dir):
            if not (fname.endswith(".npz") or fname.endswith(".json")):
                continue
            m = pattern.search(fname)
            if m:
                num = int(m.group(1))
                files_by_number.setdefault(num, []).append(fname)
        return files_by_number

    def _send_file(self, conn, fname):
        """Send file to client."""
        logging.info("[SERVER] Starting function")
        path = os.path.join(self.data_dir, fname)
        with open(path, "rb") as f:
            data = f.read()
        conn.sendall(len(fname).to_bytes(4, "big"))
        conn.sendall(fname.encode())
        conn.sendall(len(data).to_bytes(8, "big"))
        conn.sendall(data)
        os.remove(path)
        logging.info(f"[DATA] Sent {fname}")

    def _remove_all_files(self):
        """Remove all present old files."""
        logging.info("[SERVER] Starting function")
        removed = []
        for fname in os.listdir(self.data_dir):
            if fname.endswith(".npz") or fname.endswith(".json"):
                try:
                    os.remove(os.path.join(self.data_dir, fname))
                    removed.append(fname)
                except Exception as e:
                    logging.error(f"[CLEAN] failed to remove {fname}: {e}")
        logging.info(f"[CLEAN] removed {len(removed)} files")
        return removed

    def save_worker(self):
        """Concurrent save worker, saves IQ data in npz and json for metadata."""
        logging.info("[SERVER] Starting function")
        while True:
            file_index, tot_i, tot_q, t0, counters = self.save_queue.get()
            if self.server_state == "running":
                try:
                    for idx, k in enumerate(self.metadata):
                        # valid_counter_port is now shared by all lock-ins of
                        # a group (hardware constraint), so per-channel
                        # diagnostics are only available at group granularity.
                        group_counter = counters[idx // self.group_size]
                        self.metadata[k]["t0"] = t0 + int(group_counter) / 122.88e6
                        self.metadata[k]["counter"] = int(group_counter)

                    np.savez_compressed(
                        os.path.join(self.data_dir, f"ivals_{file_index}.npz"),
                        tot_i,
                    )
                    np.savez_compressed(
                        os.path.join(self.data_dir, f"qvals_{file_index}.npz"),
                        tot_q,
                    )

                    with open(
                        os.path.join(self.data_dir, f"config_{file_index}.json"),
                        "w",
                    ) as f:
                        json.dump(self.metadata, f)

                    logging.info(f"[SAVE] Saving files with index {file_index}")
                finally:
                    self.save_queue.task_done()

    def start(self):
        """Manage subthreads and loading the overlay."""
        logging.info("[SERVER] Starting function")
        self.overlay, self.controller, self.lockins, self.sync, self.dma_groups = (
            load_overlay(verbose=True)
        )
        self.group_size = len(self.lockins) // len(self.dma_groups)
        self.dmas = None
        logging.info("[ACQ] Overlay loaded")

        # threading.Thread(target=self.start_data_server, daemon=True).start()
        threading.Thread(target=self.save_worker, daemon=True).start()
        threading.Thread(target=self.start_control_server, daemon=True).start()

        while True:
            if self.reload_event.is_set():
                logging.info("[MAIN] Reloading overlay")

                (
                    self.overlay,
                    self.controller,
                    self.lockins,
                    self.sync,
                    self.dma_groups,
                ) = load_overlay()
                self.group_size = len(self.lockins) // len(self.dma_groups)
                load_lo_config(self, FW_VERSION)
                self.dmas = None

                self.reload_event.clear()
                self.reload_done.set()

            threading.Event().wait(0.1)
