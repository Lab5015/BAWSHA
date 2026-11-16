#!/usr/bin/env python3
"""Approximate simulation of the RFSoC lock-in chain, ADC samples -> int32 I/Q output.

Model (one lock-in, I and Q):
  ADC (122.88 MS/s seen by the lock-in, 16-bit word, 14-bit ADC left-justified)
    -> DDS (18 bit) x ADC, product cut at bit 18 -> 16 bit        (multiplier.vhd)
    -> FIR chain x2 x3 x5 x5 x5 x5 x5 x5 x5 (decimation 468750)  (lockin.tcl, 32-bit words)
    -> int32 I, Q at 262.144 Hz.
FIR stages are bit-true up to the unknown output-bit alignment: output = round(sum(c*x) / 2^L),
L = ceil(log2(sum|c|)) (full precision for the first x2). This gives a DC gain of ~128 for the
whole chain, consistent with the -46 count offset seen in real data (-0.375 LSB x 128).

Input: white noise (rms, 16-bit counts, 0..32767) + optional tone burst (frequency = LO + offset). Ideal DDS.
Front end: 'avg12' (new firmware: mean of the 12 ADC samples); --old-fw (headless) = old firmware (sample 0, biased multiplier).

Usage:
  python sim_lockin_chain.py                       # interactive dashboard
  python sim_lockin_chain.py --save out.png [--lo 9 --offset 20 --amp 400 --noise 80 ...]   # headless, one run
Needs numpy, scipy, matplotlib. Memory: processed in chunks of 4 outputs (~1.9M samples), < 300 MB.
"""
import argparse
import math
import re
import time
from pathlib import Path

import numpy as np
from scipy.signal import upfirdn

FS = 122.88e6          # lock-in clock / sample rate
FS_ADC = 1474.56e6     # RFDC sample rate (12 samples per clock)
FIR_DEC = 468750
FS_OUT = FS / FIR_DEC
CHUNK_OUT = 4          # outputs per processing chunk
DDS_AMP = 131071       # 18-bit DDS peak
SETTLE = 36            # outputs discarded (filter settling: last FIR spans 23 outputs, the others ~10 more)
STAGES = ["fir_x2", "fir_x3", "fir_x5", "fir_x5_1", "fir_x5_2", "fir_x5_3", "fir_x5_4",
          "fir_compiler_x5", "fir_compiler_x5_2"]
DEFAULT_TCL = Path(__file__).resolve().parent.parent / "rfsoc_control" / "firmware" / "bd" / "lockin.tcl"


# ----------------------------------------------------------------------------- FIR chain

class Stage:
    """Decimating FIR with 32-bit output bit selection, processed chunk by chunk."""

    def __init__(self, name, h, dec, rounding, shift):
        self.name, self.h, self.dec, self.rounding, self.shift = name, np.asarray(h, float), dec, rounding, shift
        self.tail_len = math.ceil((len(h) - 1) / dec) * dec
        self.reset()

    def reset(self):
        self.tail = np.zeros(self.tail_len)

    def process(self, x):
        xe = np.concatenate([self.tail, x])
        self.tail = xe[-self.tail_len:] if self.tail_len else xe[:0]
        y = upfirdn(self.h, xe, 1, self.dec)
        y = y[self.tail_len // self.dec: self.tail_len // self.dec + len(x) // self.dec]
        if self.rounding == "full":
            return y
        y = y / 2.0 ** self.shift
        return np.rint(y) if self.rounding == "convergent" else np.floor(y)


def load_stages(tcl_path):
    text = Path(tcl_path).read_text().replace("\\\n", " ")
    stages = []
    for name in STAGES:
        block = re.search(r"set %s \[ create_bd_cell.*?\] \$%s" % (name, name), text, re.S).group(0)

        def get(key, default=None):
            m = re.search(r"CONFIG\.%s \{(.*?)\}" % key, block, re.S)
            return m.group(1) if m else default

        c = [int(v) for v in re.split(r"[,\s]+", get("CoefficientVector")) if re.fullmatch(r"-?\d+", v)]
        mode = get("Output_Rounding_Mode")
        rounding = {"Full_Precision": "full", "Truncate_LSBs": "truncate"}.get(mode, "convergent")
        shift = math.ceil(math.log2(sum(abs(v) for v in c)))
        stages.append(Stage(name, c, int(get("Decimation_Rate")), rounding, shift))
    return stages


# ----------------------------------------------------------------------------- stats

class Acc:
    """Running statistics of a stream (rms, max, mean, optional unique values)."""

    def __init__(self, track_unique=False):
        self.n = 0; self.s = 0.0; self.s2 = 0.0; self.mx = 0.0
        self.uniq = set() if track_unique else None

    def add(self, x):
        x = np.asarray(x, float)
        self.n += x.size; self.s += x.sum(); self.s2 += (x * x).sum()
        self.mx = max(self.mx, float(np.abs(x).max()))
        if self.uniq is not None:
            self.uniq.update(np.unique(x.astype(np.int64)).tolist())

    def row(self, width):
        mean = self.s / max(self.n, 1)
        rms = math.sqrt(max(self.s2 / max(self.n, 1) - mean * mean, 0.0))
        bits = math.ceil(math.log2(self.mx + 1)) + 1
        return dict(mean=mean, std=rms, maxabs=self.mx, bits=bits, width=width,
                    unique=len(self.uniq) if self.uniq is not None else None)


# ----------------------------------------------------------------------------- simulation

_TAB = []


def _dds_table():
    """18-bit-address cosine table, 18-bit amplitude (stand-in for the DDS)."""
    if not _TAB:
        _TAB.append(np.rint(DDS_AMP * np.cos(2 * np.pi * np.arange(2 ** 18) / 2 ** 18)).astype(np.float32))
    return _TAB[0]


def simulate(p, chains, progress=None):
    """p: dict(lo_mhz, offset_hz, amp, noise, t_start_ms, t_len_ms, n_out, frontend, mult).
    amp = tone peak and noise = white noise rms, both in 16-bit ADC counts at the ADC sample rate.
    chains: (stages for I, stages for Q), each its own filter state."""
    rng = np.random.default_rng(1)
    stages = chains[0]
    for chain in chains:
        for s in chain:
            s.reset()
    f_lo = p["lo_mhz"] * 1e6
    f_tone = f_lo + p["offset_hz"]
    fw = int(round(f_lo / FS * 2 ** 32))
    avg12 = p["frontend"] == "avg12"
    if avg12:   # boxcar droop of the 12-sample mean, white noise reduced by sqrt(12)
        arg = math.pi * f_tone / FS_ADC
        gain = math.sin(12 * arg) / (12 * math.sin(arg)) if arg > 0 else 1.0
        sigma16 = p["noise"] / math.sqrt(12)
    else:
        gain, sigma16 = 1.0, p["noise"]
    amp16 = p["amp"] * gain
    n_out = int(round(p["n_out"]))
    chunk = CHUNK_OUT * FIR_DEC
    n_chunks = math.ceil(n_out / CHUNK_OUT)
    t0, t1 = p["t_start_ms"] * 1e-3, (p["t_start_ms"] + p["t_len_ms"]) * 1e-3

    adc_acc, mix_acc = Acc(True), Acc(True)
    st_acc = [Acc() for _ in stages]
    out_i, out_q = [], []
    adc_snip = None
    fwt = np.uint32(int(round(f_tone / FS * 2 ** 32)) & 0xFFFFFFFF)
    fwl = np.uint32(fw & 0xFFFFFFFF)
    s0, s1 = int(round(t0 * FS)), int(round(t1 * FS))
    for ci in range(n_chunks):
        a0 = ci * chunk
        t = np.arange(a0, a0 + chunk, dtype=np.uint32)      # uint32 products wrap = 32-bit phase accumulator
        x = rng.standard_normal(chunk, dtype=np.float32) * np.float32(sigma16)
        lo, hi = max(s0, a0) - a0, min(s1, a0 + chunk) - a0
        if amp16 > 0 and hi > lo:
            x[lo:hi] += np.float32(amp16) * _dds_table()[(t[lo:hi] * fwt) >> 14] / np.float32(DDS_AMP)
        x = np.rint(x / 4) * 4 if not avg12 else np.rint(x)
        adc = np.clip(x, -32768, 32767).astype(np.int64)
        idx = (t * fwl) >> 14                               # 18-bit phase address into the DDS table
        dds_i = _dds_table()[idx].astype(np.int64)
        dds_q = _dds_table()[(idx + (1 << 16)) & 0x3FFFF].astype(np.int64)
        mixed = []
        for dds in (dds_i, dds_q):
            prod = dds * adc
            if p["mult"] == "old":
                m = (prod + 2 ** 15) >> 18          # old rounding constant (bug): bias -0.375 LSB
            else:                                   # round half to even
                m = (prod + (2 ** 17 - 1) + ((prod >> 18) & 1)) >> 18
            mixed.append(np.clip(m, -32768, 32767).astype(float))
        record = ci * CHUNK_OUT >= SETTLE
        if ci == 0:
            adc_snip = adc[:3000].copy()
        if record:
            adc_acc.add(adc); mix_acc.add(mixed[0])
        for k, chan in enumerate(mixed):
            y = chan
            for si, s in enumerate(chains[k]):
                y = s.process(y)
                if record and k == 0:
                    st_acc[si].add(y)
            (out_i if k == 0 else out_q).append(y)
        if progress:
            progress((ci + 1) / n_chunks)
    out_i = np.concatenate(out_i)[:n_out]
    out_q = np.concatenate(out_q)[:n_out]
    rows = [("ADC (16-bit word)", adc_acc.row(16)), ("mixer out (16)", mix_acc.row(16))]
    for s, a in zip(stages, st_acc):
        rows.append((s.name, a.row(32)))
    # expected tone magnitude at the output: mixer DC = amp16/4, chain DC gain ~128 -> 32 x amp16
    info = dict(expected_amp=32.0 * amp16, gain=gain, sigma16=sigma16, f_tone=f_tone, adc_snip=adc_snip)
    return out_i, out_q, rows, info


def table_text(rows):
    lines = ["%-18s %9s %9s %8s %6s %6s" % ("stage", "mean", "std", "max|x|", "bits", "unique")]
    for name, r in rows:
        lines.append("%-18s %9.1f %9.1f %8.0f %3d/%-2d %6s" % (
            name, r["mean"], r["std"], r["maxabs"], r["bits"], r["width"],
            "" if r["unique"] is None else r["unique"]))
    return "\n".join(lines)


# ----------------------------------------------------------------------------- plotting

def draw(fig_axes, p, out_i, out_q, rows, info, final_unique):
    ax_adc, ax_bits, ax_ts, ax_hist, ax_mag, ax_txt = fig_axes
    for a in fig_axes:
        a.clear()
    snip = info["adc_snip"]
    ax_adc.plot(np.arange(len(snip)) / FS * 1e6, snip, lw=0.6)
    ax_adc.set(title="ADC samples after the 12-sample average, first 25 us", xlabel="us", ylabel="counts")

    names = [n for n, _ in rows]
    bits = [r["bits"] for _, r in rows]
    widths = [r["width"] for _, r in rows]
    y = np.arange(len(rows))[::-1]
    ax_bits.barh(y, widths, color="0.85", label="word width")
    ax_bits.barh(y, bits, color="C0", label="bits used (max|x|)")
    ax_bits.set_yticks(y); ax_bits.set_yticklabels(names, fontsize=7)
    ax_bits.set(title="size of the numbers along the chain", xlabel="bits (incl. sign)")
    for yy, (n, r) in zip(y, rows):
        ax_bits.text(widths[0] * 0 + 0.5, yy, "max %.0f" % r["maxabs"], fontsize=6, va="center", color="w")
    ax_bits.legend(fontsize=6, loc="lower right")

    t = np.arange(len(out_i)) / FS_OUT * 1e3
    ax_ts.step(t, out_i, where="post", lw=0.8, label="I")
    ax_ts.step(t, out_q, where="post", lw=0.8, label="Q")
    ax_ts.axvspan(p["t_start_ms"], p["t_start_ms"] + p["t_len_ms"], color="C1", alpha=0.15,
                  label="tone" if p["amp"] > 0 else None)
    ax_ts.axvspan(0, SETTLE / FS_OUT * 1e3, color="0.5", alpha=0.2, label="settling (ignored)")
    ax_ts.set(title="output I, Q (int32 counts)", xlabel="ms", ylabel="counts"); ax_ts.legend(fontsize=6)

    i_s, q_s = out_i[SETTLE:], out_q[SETTLE:]
    lo, hi = int(min(i_s.min(), q_s.min())), int(max(i_s.max(), q_s.max()))
    bins = np.arange(lo - 0.5, hi + 1.5, max(1, (hi - lo) // 300 or 1))
    ax_hist.hist(i_s, bins=bins, alpha=0.6, label="I"); ax_hist.hist(q_s, bins=bins, alpha=0.6, label="Q")
    ax_hist.set(title="final values: %d distinct (I: %d)" % (final_unique, len(np.unique(i_s))),
                xlabel="counts", ylabel="n"); ax_hist.legend(fontsize=6)

    mag = np.hypot(out_i, out_q)
    ax_mag.plot(t, mag, lw=0.8, label="|I+jQ|")
    if p["amp"] > 0:
        ax_mag.axhline(info["expected_amp"], color="C3", ls="--", lw=0.8,
                       label="expected ~32 x amp16 = %.0f" % info["expected_amp"])
    ax_mag.axvspan(0, SETTLE / FS_OUT * 1e3, color="0.5", alpha=0.2)
    ax_mag.set(title="magnitude", xlabel="ms", ylabel="counts"); ax_mag.legend(fontsize=6)

    ax_txt.axis("off")
    ax_txt.text(0, 1, table_text(rows), family="monospace", fontsize=5.6, va="top")


# ----------------------------------------------------------------------------- main

def run_once(p, chains, progress=None):
    out_i, out_q, rows, info = simulate(p, chains, progress)
    i_s, q_s = out_i[SETTLE:], out_q[SETTLE:]
    final_unique = len(np.unique(np.concatenate([i_s, q_s]).astype(np.int64)))
    acc = Acc(True)
    acc.add(i_s)
    rows.append(("OUTPUT I (int32)", acc.row(32)))
    return out_i, out_q, rows, info, final_unique


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tcl", default=str(DEFAULT_TCL), help="lockin.tcl with the FIR coefficients")
    ap.add_argument("--save", help="run once headless and save the figure to this PNG")
    ap.add_argument("--lo", type=float, default=9.0, help="LO frequency [MHz]")
    ap.add_argument("--offset", type=float, default=20.0, help="tone offset from LO [Hz]")
    ap.add_argument("--amp", type=float, default=None,
                    help="tone amplitude, peak [16-bit counts, 0..32767]; 0 = no tone (dashboard default 400)")
    ap.add_argument("--noise", type=float, default=80.0,
                    help="white ADC noise rms [16-bit counts, 0..32767]; 80 is about what the old data show")
    ap.add_argument("--start", type=float, default=160.0, help="tone start [ms]")
    ap.add_argument("--length", type=float, default=100.0, help="tone duration [ms]")
    ap.add_argument("--nout", type=int, default=90, help="output samples to simulate (> %d)" % SETTLE)
    ap.add_argument("--old-fw", action="store_true",
                    help="old firmware (sample 0 only, multiplier with -0.375 LSB bias); headless use")
    a = ap.parse_args()
    chains = (load_stages(a.tcl), load_stages(a.tcl))
    p = dict(lo_mhz=a.lo, offset_hz=a.offset, amp=0.0 if a.amp is None and a.save else (400.0 if a.amp is None else a.amp),
             noise=a.noise, t_start_ms=a.start, t_len_ms=a.length, n_out=a.nout,
             frontend="sample0" if a.old_fw else "avg12", mult="old" if a.old_fw else "fixed")

    import matplotlib
    if a.save:
        matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.widgets import Button, Slider, TextBox

    fig = plt.figure(figsize=(16, 9.5))
    gs = fig.add_gridspec(2, 3, left=0.32, right=0.985, top=0.95, bottom=0.07, wspace=0.28, hspace=0.38)
    axes = [fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1]), fig.add_subplot(gs[0, 2]),
            fig.add_subplot(gs[1, 0]), fig.add_subplot(gs[1, 1]), fig.add_subplot(gs[1, 2])]
    status = fig.text(0.01, 0.015, "", fontsize=8)
    info_txt = fig.text(0.02, 0.215, "", fontsize=8, family="monospace")

    def go(_=None):
        t_start = time.time()
        status.set_text("running ...")
        fig.canvas.draw_idle(); fig.canvas.flush_events()
        def progress(frac):
            status.set_text("running ... %d %%" % (100 * frac))
            fig.canvas.flush_events()

        out_i, out_q, rows, info, fu = run_once(p, chains, None if a.save else progress)
        draw(axes, p, out_i, out_q, rows, info, fu)
        warn = ""
        if p["amp"] > 0 and p["t_start_ms"] >= int(round(p["n_out"])) / FS_OUT * 1e3:
            warn = "   WARNING: tone starts after the end of the simulated time (%.0f ms)" % (int(round(p["n_out"])) / FS_OUT * 1e3)
        status.set_text("done in %.1f s   (tone at %.6f MHz, boxcar gain %.3f)%s" % (
            time.time() - t_start, info["f_tone"] / 1e6, info["gain"], warn))
        fig.canvas.draw_idle()
        return rows, fu

    if a.save:
        rows, fu = go()
        fig.savefig(a.save, dpi=130)
        print(table_text(rows))
        print("distinct output values after settling (I and Q together): %d" % fu)
        return

    FULL = 32767.0

    def dbfs(v):
        return "-inf" if v <= 0 else "%.1f" % (20 * math.log10(v / 32768.0))

    def refresh_info():
        amp, noise = p["amp"], p["noise"]
        snr = "inf" if noise <= 0 else "%.1f" % (20 * math.log10(max(amp, 1e-9) / math.sqrt(2) / noise))
        info_txt.set_text("tone  %7.0f counts peak = %s dBFS\nnoise %7.0f counts rms  = %s dBFS\n"
                          "tone/noise (at ADC, rms) = %s dB" % (amp, dbfs(amp), noise, dbfs(noise), snr))
        fig.canvas.draw_idle()

    ctrl = []   # keep references so the widgets stay alive

    def control(row, label, key, lo, hi, fmt, cubic=False):
        """Slider (0..1 position, cubic for the counts so small values stay reachable) + typed value."""
        y = 0.885 - 0.075 * row
        fig.text(0.02, y + 0.035, label, fontsize=8.5)
        to_pos = (lambda v: (v / hi) ** (1 / 3)) if cubic else (lambda v: v)
        from_pos = (lambda x: hi * x ** 3) if cubic else (lambda x: x)
        sl = Slider(fig.add_axes([0.02, y, 0.17, 0.022]), "", to_pos(lo), to_pos(hi), valinit=to_pos(p[key]))
        sl.valtext.set_visible(False)
        tb = TextBox(fig.add_axes([0.215, y - 0.004, 0.075, 0.03]), "", initial=fmt % p[key])
        busy = [False]

        def on_slide(x):
            if busy[0]:
                return
            p[key] = float(from_pos(x))
            busy[0] = True; tb.set_val(fmt % p[key]); busy[0] = False
            refresh_info()

        def on_text(txt):
            if busy[0]:
                return
            try:
                v = min(max(float(txt), lo), hi)
            except ValueError:
                return
            p[key] = v
            busy[0] = True; sl.set_val(to_pos(v)); busy[0] = False
            refresh_info()

        sl.on_changed(on_slide); tb.on_submit(on_text)
        ctrl.extend([sl, tb])

    fig.text(0.02, 0.965, "Lock-in chain simulator", fontsize=13, weight="bold")
    fig.text(0.02, 0.945, "new firmware: 12-sample average, fixed multiplier", fontsize=8, color="0.4")
    control(0, "ADC signal: LO frequency [MHz]", "lo_mhz", 0.5, 60.0, "%.4g")
    control(1, "ADC signal: tone minus LO [Hz]", "offset_hz", -130.0, 130.0, "%.4g")
    control(2, "ADC signal: tone amplitude, peak [counts]", "amp", 0.0, FULL, "%.4g", cubic=True)
    control(3, "ADC noise: white, rms [counts]", "noise", 0.0, FULL, "%.4g", cubic=True)
    control(4, "tone starts at [ms]", "t_start_ms", 0.0, 1000.0, "%.4g")
    control(5, "tone lasts [ms]", "t_len_ms", 4.0, 800.0, "%.4g")
    control(6, "simulated duration [outputs, 3.8 ms each]", "n_out", SETTLE + 20.0, 300.0, "%.0f")
    refresh_info()
    btn = Button(fig.add_axes([0.05, 0.145, 0.20, 0.05]), "RUN")
    btn.on_clicked(go)
    ctrl.append(btn)
    fig.text(0.02, 0.06, "Counts are on the 16-bit ADC word (full scale 32767; the real ADC has\n"
             "14 bits, so 1 ADC LSB = 4 counts). Drag a slider or type a value and\n"
             "press Enter, then press RUN (some seconds).\n"
             "The first %d outputs are filter settling and are not counted." % SETTLE, fontsize=7.5)
    for ax in axes:
        ax.text(0.5, 0.5, "press RUN", ha="center", va="center", transform=ax.transAxes, color="0.6")
    plt.show()


if __name__ == "__main__":
    main()
