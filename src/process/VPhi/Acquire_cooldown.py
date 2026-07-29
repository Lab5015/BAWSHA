#!/usr/bin/env python3
"""
CooldownScan.py — Acquisizioni continue durante il cooldown del criostato.

Flusso:
  1. Connette al Proteox e imposta un setpoint iniziale (opzionale)
  2. Ogni INTERVAL_S secondi lancia un'acquisizione singola dallo scope
  3. Salva Time, CH1 (Flux), CH2 (Volt) in un HDF5 con gruppo per ogni acquisizione
  4. Aggiunge come attributi al gruppo: timestamp, T_coldplate_K, T_mixing_K
  5. Si ferma dopo MAX_DURATION_S secondi totali (o Ctrl+C)

Output: <OUTPUT_FILE>  (singolo HDF5 con N gruppi, uno per acquisizione)
Log:    <OUTPUT_DIR>/cooldown_<timestamp>.log

Usage:
    python /home/bausciadaq/BAWSHA/src/process/VPhi/Acquire_cooldown.py
"""

import asyncio
import logging
import threading
import time
from datetime import datetime
from pathlib import Path

import h5py
import numpy as np
import sys
sys.path.insert(0, "/home/bausciadaq/BAWSHA/src/instruments/")
from TBS2000B import TBS2000B  # now Python can find it
from qtics import Proteox


# ══════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE  — modifica qui
# ══════════════════════════════════════════════════════════════════

CONFIG = {
    # Output
    "output_dir":  "/home/bausciadaq/Run6/DAQ/TempScans/",   # cartella per HDF5 e log
    "output_file": "Vphi_ch3_cooldown_highT_WP.hdf5",  # nome del file HDF5

    # Timing
    "max_duration_s": 2100,   # durata massima totale in secondi (1 ora)
    "interval_s":     20,      # pausa (s) tra la fine di un'acquisizione e l'inizio della prossima

    # Oscilloscopio (TBS2000B)
    "scope": {
        "desired_rate":  100_000,   # campionamento desiderato (Sa/s)
        "record_length":   20_000,   # numero di punti per acquisizione
        "scale": 0.2,
        "scale2":0.05,
        "avg": True,
        "navg": 128,
    },

    # Criostato (Proteox)
    "fridge": {
        "initial_setpoint_K":0.020,   # None = scende liberamente, es. 0.020 per 20 mK
    },
}


# ══════════════════════════════════════════════════════════════════
#  ASYNC EVENT LOOP  (condiviso per tutta la sessione, come in TempScan)
# ══════════════════════════════════════════════════════════════════

_loop: asyncio.AbstractEventLoop = None


def _run(coro):
    """Esegui una coroutine sul loop condiviso e ritorna il risultato (bloccante)."""
    fut = asyncio.run_coroutine_threadsafe(coro, _loop)
    return fut.result()


# ══════════════════════════════════════════════════════════════════
#  OXFORD INSTRUMENTS API WRAPPER
# ══════════════════════════════════════════════════════════════════

def oi_connect() -> Proteox:
    global _loop

    async def _connect():
        instrument = Proteox()
        await instrument.connect()
        return instrument

    _loop = asyncio.new_event_loop()
    t = threading.Thread(target=_loop.run_forever, daemon=True)
    t.start()
    return _run(_connect())


def oi_set_mixing_setpoint(client: Proteox, temperature_K: float) -> None:
    _run(client.set_MC_T(temperature_K))


def oi_get_mixing_temperature(client: Proteox) -> float:
    return _run(client.get_MC_T())


def oi_get_coldplate_temperature(client: Proteox) -> float:
    return _run(client.get_CP_T())


def oi_disconnect(client: Proteox) -> None:
    _run(client.close())
    _loop.call_soon_threadsafe(_loop.stop)


# ══════════════════════════════════════════════════════════════════
#  LOGGING
# ══════════════════════════════════════════════════════════════════

def setup_logging(output_dir: str) -> logging.Logger:
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"{output_dir}/cooldown_{ts}.log"
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(log_file),
        ],
    )
    return logging.getLogger(__name__)


# ══════════════════════════════════════════════════════════════════
#  LETTURA TEMPERATURA  (con fallback a NaN se la lettura fallisce)
# ══════════════════════════════════════════════════════════════════

def read_temperatures(client: Proteox, log: logging.Logger) -> tuple[float, float]:
    """Ritorna (T_coldplate_K, T_mixing_K). NaN se la lettura fallisce."""
    try:
        cp_K = oi_get_coldplate_temperature(client)
    except Exception as exc:
        log.warning(f"  Cold plate read error: {exc}")
        cp_K = float("nan")

    try:
        mx_K = oi_get_mixing_temperature(client)
    except Exception as exc:
        log.warning(f"  Mixing read error: {exc}")
        mx_K = float("nan")

    return cp_K, mx_K


# ══════════════════════════════════════════════════════════════════
#  ACQUISIZIONE SCOPE
# ══════════════════════════════════════════════════════════════════

def acquire_waveform(desired_rate: int, record_length: int, scale: float, scale2: float, navg:int, log: logging.Logger, avg: bool) -> dict | None:
    """
    Acquisisce una singola curva dallo scope.
    Ritorna il dict {time, CH1, CH2} oppure None se fallisce.
    """
    scope = None
    try:
        scope = TBS2000B()
        scope.set_vertical_scale(1, scale)
        scope.set_vertical_scale(2, scale2)
        if avg:
            result = scope.acquire_averaged_curve(navg, desired_rate, record_length)
        else:
            result = scope.acquire_single_curve(desired_rate, record_length)
        return result
    except Exception as exc:
        log.error(f"  Acquisizione scope fallita: {exc}")
        return None
    finally:
        if scope is not None:
            try:
                del scope
            except Exception:
                pass


# ══════════════════════════════════════════════════════════════════
#  SALVATAGGIO HDF5
# ══════════════════════════════════════════════════════════════════

def save_to_hdf5(
    hdf5_path: str,
    acq_index: int,
    result: dict,
    cp_K: float,
    mx_K: float,
    timestamp_iso: str,
    log: logging.Logger,
) -> str:
    """
    Apre (o crea) l'HDF5 e salva i dati dell'acquisizione corrente.
    Il nome del gruppo è  acq_<NNNN>_<timestamp>.
    Ritorna il nome del gruppo creato.
    """
    groupname = f"acq_{acq_index:04d}_{timestamp_iso}"

    with h5py.File(hdf5_path, "a") as f:
        if groupname in f:
            log.warning(f"  Gruppo {groupname} già presente — sovrascritto")
            del f[groupname]

        grp = f.create_group(groupname)

        # Dataset
        grp.create_dataset("Time", data=np.array(result["time"]),   compression="gzip")
        grp.create_dataset("Flux", data=np.array(result["CH1"]),    compression="gzip")
        grp.create_dataset("Volt", data=np.array(result["CH2"]),    compression="gzip")

        # Metadata come attributi
        grp.attrs["timestamp"]        = timestamp_iso
        grp.attrs["acq_index"]        = acq_index
        grp.attrs["T_coldplate_K"]    = cp_K
        grp.attrs["T_mixing_K"]       = mx_K
        grp.attrs["T_coldplate_mK"]   = cp_K * 1e3
        grp.attrs["T_mixing_mK"]      = mx_K * 1e3

    log.info(
        f"  Salvato → {groupname}  "
        f"[CP={cp_K*1e3:.2f} mK, MC={mx_K*1e3:.2f} mK]"
    )
    return groupname


# ══════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════

def main() -> None:
    cfg         = CONFIG
    output_dir  = cfg["output_dir"]
    output_file = str(Path(output_dir) / cfg["output_file"])
    log         = setup_logging(output_dir)

    max_s       = float(cfg["max_duration_s"])
    interval_s  = float(cfg["interval_s"])
    scope_rate  = int(cfg["scope"]["desired_rate"])
    scope_rlen  = int(cfg["scope"]["record_length"])
    scope_scale = float(cfg["scope"]["scale"])
    scope_scale2 = float(cfg["scope"]["scale2"])
    scope_navg = int(cfg["scope"]["navg"])
    scope_avg = cfg["scope"]["avg"]
    setpoint_K  = cfg["fridge"].get("initial_setpoint_K")

    log.info("═" * 60)
    log.info("CooldownScan avviato")
    log.info(f"  Output HDF5   : {output_file}")
    log.info(f"  Durata max    : {max_s/3600:.2f} h")
    log.info(f"  Intervallo    : {interval_s:.1f} s")
    log.info(f"  Sample rate   : {scope_rate/1e6:.1f} MS/s   "
             f"Record length: {scope_rlen/1e3:.0f} k pts")
    log.info("═" * 60)

    # Connessione criostato
    client = None
    try:
        client = oi_connect()
        log.info("Connesso al fridge controller (Proteox)")
    except Exception as exc:
        log.error(f"Connessione fridge fallita: {exc} — continuo senza telemetria")

    # Setpoint iniziale (opzionale)
    if client is not None and setpoint_K is not None:
        try:
            oi_set_mixing_setpoint(client, setpoint_K)
            log.info(f"Setpoint mixing impostato a {setpoint_K*1e3:.1f} mK")
        except Exception as exc:
            log.warning(f"Impossibile impostare setpoint: {exc}")

    # Loop principale
    t_start    = time.monotonic()
    acq_index  = 0
    ok_count   = 0
    fail_count = 0

    try:
        while True:
            elapsed = time.monotonic() - t_start

            if elapsed >= max_s:
                log.info(f"Durata massima raggiunta ({max_s/3600:.2f} h) — fine.")
                break

            log.info(f"── Acquisizione #{acq_index+1}  (elapsed {elapsed/60:.1f} min) ──")

            # Leggi temperature prima dell'acquisizione
            ts_iso = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            if client is not None:
                cp_K, mx_K = read_temperatures(client, log)
                log.info(f"  T_coldplate={cp_K*1e3:.2f} mK   T_mixing={mx_K*1e3:.2f} mK")
            else:
                cp_K, mx_K = float("nan"), float("nan")

            # Acquisizione scope
            result = acquire_waveform(scope_rate, scope_rlen, scope_scale, scope_scale2, scope_navg, log, scope_avg)

            if result is not None:
                try:
                    save_to_hdf5(output_file, acq_index, result, cp_K, mx_K, ts_iso, log)
                    ok_count += 1
                except Exception as exc:
                    log.error(f"  Salvataggio HDF5 fallito: {exc}")
                    fail_count += 1
            else:
                log.warning(f"  Acquisizione #{acq_index+1} fallita — passo saltato")
                fail_count += 1

            acq_index += 1

            # Attendi il prossimo ciclo (con uscita anticipata se il tempo è scaduto)
            remaining = max_s - (time.monotonic() - t_start)
            if remaining <= 0:
                break
            sleep_time = min(interval_s, remaining)
            log.info(f"  Attendo {sleep_time:.1f} s prima della prossima acquisizione…")
            time.sleep(sleep_time)

    except KeyboardInterrupt:
        log.info("Interruzione manuale (Ctrl+C) — chiudo.")

    # Disconnessione
    if client is not None:
        try:
            oi_disconnect(client)
            log.info("Disconnesso dal fridge controller")
        except Exception as exc:
            log.warning(f"Disconnessione fallita: {exc}")

    log.info("")
    log.info("═" * 60)
    log.info(f"Sessione terminata — Acquisizioni OK: {ok_count}   FALLITE: {fail_count}")
    log.info(f"HDF5 salvato in: {output_file}")
    log.info("═" * 60)


if __name__ == "__main__":
    main()