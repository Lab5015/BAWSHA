"""
Noise4channels.py
================
Acquire repeated noise traces on CH1–CH4 of the Tektronix TBS2000B and save
them to an HDF5 file.

File layout
-----------
    <output.h5>
    ├── metadata/               (global attributes on this group)
    │   actual_sample_rate_Hz
    │   actual_record_length
    │   n_records              (= n_traces)
    │   points_per_record
    │   desired_sample_rate_Hz
    │   vertical_scale_V_per_div
    │   channels
    │   timestamp_start        (ISO-8601)
    │
    ├── time                    (1-D array, seconds, shared by all traces)
    │
    └── trace_0000/
    │   ├── CH1   (1-D float64 array, volts)
    │   ├── CH2
    │   ├── CH3
    │   └── CH4
    ├── trace_0001/
    │   └── ...

Usage (CLI)
-----------
    python Noise4channels.py                          # all defaults
    python Noise4channels.py --n-traces 200 \\
                             --sample-rate 1e6 \\
                             --record-length 10000 \\
                             --scale 0.05 \\
                             --output noise_run.h5

    # To skip the 50-Ω correction on a specific run:
    python Noise4channels.py --no-50ohm-correction

Usage (import)
--------------
    from acquire_noise import run_acquisition
    run_acquisition(n_traces=100, desired_rate=1e6, record_length=10000,
                    scale=0.05, output="noise.h5")
"""

import argparse
import time
from datetime import datetime

import h5py
import numpy as np

# ---------------------------------------------------------------------------
# The TBS2000B driver is expected to live next to this script (or on sys.path)
# ---------------------------------------------------------------------------
import sys
sys.path.insert(0, "/home/bausciadaq/BAWSHA/src/instruments/")
from TBS2000B import TBS2000B  # now Python can find it


# ---------------------------------------------------------------------------
# 4-channel acquisition  (extends the 2-channel acquire_single_curve)
# ---------------------------------------------------------------------------

CHANNELS = ["CH1", "CH2", "CH3", "CH4"]


def acquire_single_curve_4ch(
    scope: TBS2000B,
    desired_rate: float,
    record_length: int,
    correction_50ohm: bool = True,
) -> dict:
    """
    Acquire one waveform from CH1 … CH4 sequentially (no averaging).

    This mirrors the logic of TBS2000B.acquire_single_curve but iterates
    over four channels instead of two.  The horizontal timebase is
    configured once; preamble values are re-queried per channel so each
    channel's individual vertical calibration is used.

    Args:
        scope            : Connected TBS2000B instance.
        desired_rate     : Target sample rate in S/s.
        record_length    : Number of samples per acquisition.
        correction_50ohm : Divide voltages by 2 to compensate for the
                           50-Ω / 1-MΩ divider artefact. Defaults to True.

    Returns:
        dict with keys:
            "actual_rate"   (float)      : Achieved sample rate [S/s].
            "actual_RL"     (int)        : Achieved record length [samples].
            "time"          (np.ndarray) : Time axis [s].
            "CH1" … "CH4"  (np.ndarray) : Voltage arrays [V].
    """
    _, real_RL = scope.set_samplerate(desired_rate, record_length)
    xincr = float(scope.query("WFMPRE:XINCR?"))
    real_rate = 1.0 / xincr

    scope.write("ACQ:MODE SAMPLE")
    scope.write("WFMOutpre:ENCdg ASCii")
    scope.write("DATA:START 1")
    scope.write(f"DATA:STOP {int(real_RL)}")

    # --- trigger a single acquisition and wait for the record to fill ---
    scope.write("ACQuire:STATE ON")
    wait = 1.5 * real_RL * xincr
    time.sleep(max(wait, 0.5))          # at least 0.5 s so the scope is ready
    scope.write("ACQuire:STATE OFF")

    readout: dict = {
        "actual_rate": real_rate,
        "actual_RL":   int(real_RL),
        "time":        None,
    }

    for source in CHANNELS:
        scope.write(f"DATA:SOURCE {source}")

        raw  = scope.query("CURVe?")
        data = np.array([float(x) for x in raw.split(",")])

        yzero = float(scope.query("WFMOutpre:YZERo?"))
        ymult = float(scope.query("WFMOutpre:YMUlt?"))
        yoff  = float(scope.query("WFMOutpre:YOFf?"))

        volts = (data - yoff) * ymult + yzero
        if correction_50ohm:
            volts /= 2.0

        if readout["time"] is None:
            xzero = float(scope.query("WFMOutpre:XZERo?"))
            readout["time"] = xzero + np.arange(len(volts)) * xincr

        readout[source] = volts

    # Leave the scope running between acquisitions
    scope.write("ACQuire:STATE RUN")
    return readout


# ---------------------------------------------------------------------------
# Main acquisition loop
# ---------------------------------------------------------------------------

def run_acquisition(
    n_traces:         int   = 100,
    desired_rate:     float = 1e6,
    record_length:    int   = 10_000,
    scale:            float = 0.1,
    offset:           float = 0.0,
    correction_50ohm: bool  = True,
    output:           str   = "noise_data.h5",
    channels:         list  = None,
):
    """
    Full acquisition run: configure scope, loop over traces, save to HDF5.

    Args:
        n_traces         : Number of traces to acquire.
        desired_rate     : Target sample rate in S/s.
        record_length    : Points per trace.
        scale            : Vertical scale in V/div (applied to all channels).
        offset           : Vertical offset in V (applied to all channels).
        correction_50ohm : Apply ÷2 voltage correction.
        output           : Path of the output HDF5 file.
        channels         : List of channel strings to acquire and save.
                           Defaults to all four: ["CH1","CH2","CH3","CH4"].
    """
    if channels is None:
        channels = CHANNELS

    print(f"\n{'='*60}")
    print(f"  Noise acquisition  —  {n_traces} traces")
    print(f"  Target SR  : {desired_rate:.3g} S/s")
    print(f"  Record len : {record_length} pts")
    print(f"  V scale    : {scale} V/div  |  offset: {offset} V")
    print(f"  50-Ω corr  : {correction_50ohm}")
    print(f"  Output     : {output}")
    print(f"{'='*60}\n")

    with TBS2000B() as scope:
        scope.instr.timeout = 40000  # milliseconds → 40 seconds

        # --- vertical scale (same for all channels) ---
        for ch_str in channels:
            ch_num = int(ch_str[-1])
            scope.set_vertical_scale(ch_num, scale, offset)

        # --- do a throwaway acquisition to resolve the actual rate/RL ---
        print("Probing actual sample rate …")
        probe = acquire_single_curve_4ch(
            scope, desired_rate, record_length, correction_50ohm
        )
        actual_rate = probe["actual_rate"]
        actual_RL   = probe["actual_RL"]
        print(f"  Actual SR : {actual_rate:.2f} S/s")
        print(f"  Actual RL : {actual_RL} pts\n")

        timestamp_start = datetime.utcnow().isoformat() + "Z"

        with h5py.File(output, "w") as hf:

            # ---- global metadata ----------------------------------------
            meta = hf.create_group("metadata")
            meta.attrs["actual_sample_rate_Hz"]    = actual_rate
            meta.attrs["actual_record_length"]      = actual_RL
            meta.attrs["n_records"]                 = n_traces
            meta.attrs["points_per_record"]         = record_length
            meta.attrs["desired_sample_rate_Hz"]    = desired_rate
            meta.attrs["vertical_scale_V_per_div"]  = scale
            meta.attrs["vertical_offset_V"]         = offset
            meta.attrs["correction_50ohm"]          = correction_50ohm
            meta.attrs["channels"]                  = channels
            meta.attrs["timestamp_start"]           = timestamp_start

            # ---- shared time axis (from first probe acquisition) --------
            hf.create_dataset("time", data=probe["time"], compression="gzip")

            # ---- acquisition loop ---------------------------------------
            for idx in range(n_traces):
                print(f"  Acquiring trace {idx+1:>{len(str(n_traces))}}/{n_traces} …",
                      end="\r", flush=True)

                result = acquire_single_curve_4ch(
                    scope, desired_rate, record_length, correction_50ohm
                )

                grp = hf.create_group(f"trace_{idx:04d}")
                grp.attrs["actual_sample_rate_Hz"] = result["actual_rate"]
                grp.attrs["actual_record_length"]   = result["actual_RL"]

                for ch in channels:
                    grp.create_dataset(ch, data=result[ch], compression="gzip")

            print(f"\n\nDone. {n_traces} traces saved to '{output}'.")

        meta = hf if False else None   # close block already handled by `with`

    print("Scope connection closed.")


# ---------------------------------------------------------------------------
# CLI entry-point
# ---------------------------------------------------------------------------

def _parse_args():
    p = argparse.ArgumentParser(
        description="Acquire noise traces on all 4 channels of the TBS2000B."
    )
    p.add_argument("--n-traces",      type=int,   default=100,
                   help="Number of traces to acquire (default: 100)")
    p.add_argument("--sample-rate",   type=float, default=1e6,
                   help="Target sample rate in S/s (default: 1e6)")
    p.add_argument("--record-length", type=int,   default=10_000,
                   help="Points per trace (default: 10000)")
    p.add_argument("--scale",         type=float, default=0.1,
                   help="Vertical scale V/div, all channels (default: 0.1)")
    p.add_argument("--offset",        type=float, default=0.0,
                   help="Vertical offset V, all channels (default: 0.0)")
    p.add_argument("--no-50ohm-correction", dest="correction_50ohm",
                   action="store_false", default=True,
                   help="Disable the ÷2 voltage correction for 50-Ω termination")
    p.add_argument("--output",        type=str,   default="noise_data.h5",
                   help="Output HDF5 file path (default: noise_data.h5)")
    p.add_argument("--channels",      type=str,   nargs="+",
                   default=["CH1", "CH2", "CH3", "CH4"],
                   metavar="CHn",
                   help="Channels to acquire (default: CH1 CH2 CH3 CH4)")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    run_acquisition(
        n_traces         = args.n_traces,
        desired_rate     = args.sample_rate,
        record_length    = args.record_length,
        scale            = args.scale,
        offset           = args.offset,
        correction_50ohm = args.correction_50ohm,
        output           = args.output,
        channels         = args.channels,
    )