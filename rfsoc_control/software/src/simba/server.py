import argparse
import csv
import json
import logging
import os
import queue
import re
import socket
import threading
import time

import numpy as np
from logging_config import setup_logging
from pynq import allocate
from simba.utils import configure_lockin, load_overlay, start_clocks

HOST = "212.189.204.163"
PORT = 6000
PORT_DATA = 6001

DATA_DIR = "."

PACKETS = 256
N_ITER = 10
DEC_FACTOR = 1
FIR_DEC = 468750
FS = 122.88e6 / FIR_DEC / DEC_FACTOR
FW_VERSION = 1

STATE_IDLE = "idle"
STATE_RUNNING = "running"

state_lock = threading.Lock()
server_state = STATE_IDLE
stop_event = threading.Event()

save_queue = queue.Queue()
metadata = {}
FREQUENCIES = []

overlay = None
controller = None
lockins = None
sync = None

# ---------------- LO CONFIG ----------------


def load_lo_config():
    global FREQUENCIES, metadata
    FREQUENCIES = []
    metadata = {}

    with open("lo_config.csv", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            lo = int(row["LO_frequency"])
            FREQUENCIES.append(lo)
            metadata[row["name"]] = {
                "LO_frequency": lo,
                "resonance_frequency": int(row["resonance_frequency"]),
                "t0": 0,
                "counter": 0,
                "fs": FS,
                "fir_dec": FIR_DEC,
                "fw_version": FW_VERSION,
            }


def write_lo_config(config):
    with open("lo_config.csv", "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["name", "LO_frequency", "resonance_frequency"]
        )
        writer.writeheader()

        for row in config:
            writer.writerow(row)
            logging.info(
                f"[LO] name={row['name']} "
                f"LO={row['LO_frequency']} Hz "
                f"res={row['resonance_frequency']} Hz"
            )


# ---------------- SAVE WORKER ----------------


def save_worker():
    while True:
        file_index, tot_i, tot_q, t0, counters = save_queue.get()
        global server_state
        if server_state == STATE_RUNNING:
            try:
                for k in metadata:
                    metadata[k]["t0"] = t0 + int(counters[0][0]) / 122.88e6
                    metadata[k]["counter"] = int(counters[0][0])

                np.savez_compressed(f"ivals_{file_index}.npz", tot_i)
                np.savez_compressed(f"qvals_{file_index}.npz", tot_q)

                with open(f"config_{file_index}.json", "w") as f:
                    json.dump(metadata, f)

                logging.info(f"[SAVE] Saving files with index {file_index}")
            finally:
                save_queue.task_done()


# ---------------- ACQUISITION ----------------


def acquisition_loop_supervisor():
    global overlay, controller, lockins, sync, server_state

    while not stop_event.is_set():
        try:
            acquisition_loop()
            break

        except RuntimeError as e:
            logging.error(f"[ACQ] RuntimeError detected: {e}")
            logging.error("[ACQ] Restarting acquisition...")

            time.sleep(0.2)

            overlay, controller, lockins, sync = load_overlay()
            load_lo_config()

            time.sleep(0.2)

    with state_lock:
        server_state = STATE_IDLE

    remove_all_files()
    logging.info("[ACQ] Supervisor exiting")


def acquisition_loop():
    global server_state
    global overlay, controller, lockins, sync

    start_clocks(ext_clk=True)

    ibufs, qbufs, idmas, qdmas = [], [], [], []

    for idx, freq in enumerate(FREQUENCIES):
        configure_lockin(
            lockins[idx],
            frequency=freq,
            phase=0,
            dec_factor=DEC_FACTOR,
            fir_dec=FIR_DEC,
        )

        ibufs.append([allocate((PACKETS,), np.int32) for _ in range(2)])
        qbufs.append([allocate((PACKETS,), np.int32) for _ in range(2)])
        idmas.append(lockins[idx].dma_I.recvchannel)
        qdmas.append(lockins[idx].dma_Q.recvchannel)

    controller.reset(sync)
    controller.config()
    t0 = controller.start(sync, True)

    file_index = 0
    buffer_idx = 0

    logging.info("[ACQ] Running")

    try:
        while not stop_event.is_set():
            tot_i = [[] for _ in FREQUENCIES]
            tot_q = [[] for _ in FREQUENCIES]

            for it in range(N_ITER):
                for ch in range(len(FREQUENCIES)):
                    idmas[ch].transfer(ibufs[ch][buffer_idx])
                    qdmas[ch].transfer(qbufs[ch][buffer_idx])

                if it > 0:
                    prev = 1 - buffer_idx
                    for ch in range(len(FREQUENCIES)):
                        tot_i[ch].append(ibufs[ch][prev].copy())
                        tot_q[ch].append(qbufs[ch][prev].copy())

                for ch in range(len(FREQUENCIES)):
                    idmas[ch].wait()
                    qdmas[ch].wait()

                buffer_idx = 1 - buffer_idx

            for ch in range(len(FREQUENCIES)):
                tot_i[ch].append(ibufs[ch][1 - buffer_idx].copy())
                tot_q[ch].append(qbufs[ch][1 - buffer_idx].copy())

            save_queue.put(
                (
                    file_index,
                    [np.concatenate(x) for x in tot_i],
                    [np.concatenate(x) for x in tot_q],
                    t0,
                    read_counters_iq(overlay),
                )
            )

            file_index += 1
    finally:
        try:
            controller.stop(sync)
            controller.reset(sync)
        except:
            pass
        time.sleep(0.05)
        logging.info("[ACQ] loop cleanup complete")


def read_counters_iq(overlay):
    counters_ip = overlay.counters

    n_chan = 32
    counters_i = np.zeros(n_chan, dtype=np.uint64)
    counters_q = np.zeros(n_chan, dtype=np.uint64)

    for i in range(n_chan):
        # ogni canale usa 4 registri da 32 bit = 16 byte
        base = i * 16

        # offset AXI Lite in byte
        reg_i_h = base + 0
        reg_i_l = base + 4
        reg_q_h = base + 8
        reg_q_l = base + 12

        # lettura come interi Python
        i_h = int(counters_ip.read(reg_i_h))
        i_l = int(counters_ip.read(reg_i_l))
        q_h = int(counters_ip.read(reg_q_h))
        q_l = int(counters_ip.read(reg_q_l))

        # composizione 64 bit
        counters_i[i] = np.uint64((i_h << 32) | i_l)
        counters_q[i] = np.uint64((q_h << 32) | q_l)

    return counters_i, counters_q


# ---------------- CONTROL SERVER ----------------


def control_server():
    global server_state

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
    sock.bind((HOST, PORT))

    sock.listen(50)

    logging.info(f"[SERVER] listening on {PORT}")
    logging.info(f"[SERVER] firmware version {FW_VERSION}")
    logging.info(f"[SERVER] acquisition at {FS} SPS")

    global overlay, controller, lockins, sync

    try:
        while True:
            conn, _ = sock.accept()
            with conn:
                try:
                    data = conn.recv(4096)
                    if not data:
                        raise ValueError("No connection?")
                    msg = json.loads(data.decode("utf-8"))
                    if not isinstance(msg, dict):
                        raise ValueError("JSON must be object")
                    cmd = msg.get("cmd")
                except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
                    conn.sendall(
                        b'{"status":"error","msg":"Communication error, try again"}'
                    )
                with state_lock:
                    if cmd == "state_info":
                        conn.sendall(f"{server_state}".encode())
                    elif cmd == "start" and server_state == STATE_IDLE:

                        overlay, controller, lockins, sync = load_overlay()
                        logging.info("[ACQ] Overlay loaded")

                        stop_event.clear()
                        load_lo_config()

                        threading.Thread(
                            target=acquisition_loop_supervisor, daemon=True
                        ).start()
                        server_state = STATE_RUNNING
                        conn.sendall(b'{"status":"ok"}')

                    elif cmd == "stop" and server_state == STATE_RUNNING:
                        stop_event.set()
                        remove_all_files()
                        conn.sendall(b'{"status":"ok"}')

                    elif cmd == "config_lo" and server_state == STATE_IDLE:
                        write_lo_config(msg["config"])
                        conn.sendall(b'{"status":"ok"}')

                    elif cmd == "remove_files" and server_state == STATE_IDLE:
                        remove_all_files()
                        conn.sendall(b'{"status":"ok"}')

                    else:
                        conn.sendall(
                            b'{"status":"error","msg":"invalid state or command"}'
                        )
    except KeyboardInterrupt:
        logging.info("[SERVER] interrupted")
    except Exception as e:
        logging.error(f"[SERVER] {e}")
    finally:
        sock.close()
        logging.info("[SERVER] socket closed")


def remove_all_files():
    global server_state

    i = 0
    while server_state == STATE_RUNNING:
        time.sleep(0.2)
        i += 1
        if i > 10:
            break

    removed = []

    for fname in os.listdir(DATA_DIR):
        if fname.endswith(".npz") or fname.endswith(".json"):
            path = os.path.join(DATA_DIR, fname)
            try:
                os.remove(path)
                removed.append(fname)
            except Exception as e:
                logging.error(f"[CLEAN] failed to remove {fname}: {e}")

    logging.info(f"[CLEAN] removed {len(removed)} files")
    return removed


def handle_data_client(conn, addr):
    logging.info(f"[DATA] Connected {addr}")
    try:
        npz_files = [f for f in os.listdir(DATA_DIR) if f.endswith(".npz")]
        json_files = [f for f in os.listdir(DATA_DIR) if f.endswith(".json")]
        all_files = npz_files + json_files

        pattern = re.compile(r"_(\d+)\.")
        files_by_number = {}

        for fname in all_files:
            m = pattern.search(fname)
            if m:
                num = int(m.group(1))
                files_by_number.setdefault(num, []).append(fname)

        numbers = sorted(files_by_number.keys())

        if len(numbers) <= 1:
            conn.sendall((0).to_bytes(4, "big"))
            return

        for num in numbers[:-1]:
            for fname in sorted(files_by_number[num]):
                path = os.path.join(DATA_DIR, fname)
                with open(path, "rb") as f:
                    data = f.read()

                conn.sendall(len(fname).to_bytes(4, "big"))
                conn.sendall(fname.encode())
                conn.sendall(len(data).to_bytes(8, "big"))
                conn.sendall(data)

                os.remove(path)
                logging.info(f"[DATA] Sent {fname}")

        conn.sendall((0).to_bytes(4, "big"))

    finally:
        conn.close()


def data_server():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
    sock.bind((HOST, PORT_DATA))
    sock.listen(1)

    logging.info(f"[DATA] listening on {PORT_DATA}")

    try:
        while True:
            conn, addr = sock.accept()
            threading.Thread(
                target=handle_data_client, args=(conn, addr), daemon=True
            ).start()
    except KeyboardInterrupt:
        logging.info("[DATA] interrupted")
    finally:
        sock.close()
        logging.info("[DATA] socket closed")


# ---------------- MAIN ----------------


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        choices=["service", "interactive"],
        default="interactive",
    )
    args = parser.parse_args()

    setup_logging(args.mode)

    logging.info("Starting RFSoC server")

    try:
        load_lo_config()
        threading.Thread(target=data_server, daemon=True).start()
        threading.Thread(target=save_worker, daemon=True).start()
        control_server()
    except KeyboardInterrupt:
        logging.info("Shutting down cleanly...")


if __name__ == "__main__":
    main()
