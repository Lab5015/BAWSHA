#!/usr/bin/env python3
"""Verify a repair applied to .gw (HDF5) files by comparing FIXED with BACKUP.

The firmware-v3 bug delivered sample 4 three times per row (samples 4,5,6
identical) and stored in t0 the time of the last 256-sample block of the row.
The repair removes samples 5 and 6 (rows: 2560 -> 2558 samples) and sets t0 to
the time of the first sample of each row.  This script re-checks the result
independently.  Data files are only opened read-only.

Checks
  A  structure (tones, locs, keys, dtypes, info, counter, shapes, root attr)
  B  data integrity: fixed == backup without columns 5,6 (bit exact), and
     samples 5,6 == sample 4 in the backup
  C  repeated-sample rates for k = 1..15, old vs new
  D  time axis from t0 (row spacing, gaps, overlaps)
  E  absolute alignment of the new t0 from the hardware counter
  F  Welch PSD of the longest contiguous run, old vs new (comb of lines)
Checks A, D, E use metadata only and run on all tones; B, C, F read the
samples of the selected ("heavy") tones, one tone at a time.

Examples
  check_gw_fix.py --fixed run.gw                    # backup = run.gw.bak
  check_gw_fix.py --fixed run.gw --backup orig.gw --tones rk08_3A tb_5C20
  check_gw_fix.py --fixed run.gw --full --outdir check_run   # all tones
Exit code: 0 if no check FAILs, 1 otherwise.
"""
import argparse
import hashlib
import json
import os
import sys
from collections import Counter

import h5py
import numpy as np
from scipy import signal

OLD_COLS, NEW_COLS = 2560, 2558
REPEATED = (5, 6)          # columns removed by the fix (copies of column 4)
TOL = 1e-5                 # s, tolerance on t0 spacing
CHUNK_ROWS = 256
N_RATE_LAGS = 15
COMB_SPACING = 1.0         # replaced by fs/2560 at run time
C_OLD, C_NEW = "#d55e00", "#0072b2"

STATUS_ORDER = {"PASS": 0, "INFO": 0, "FAIL": 1}


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------
class Reporter:
    def __init__(self):
        self.rows = []     # (check, status, message)
        self.data = {}

    def add(self, check, status, message, **numbers):
        print("[%s] %-4s %s" % (check, status, message))
        self.rows.append((check, status, message))
        entry = self.data.setdefault(check, {"status": "PASS", "lines": [],
                                             "numbers": {}})
        if status == "FAIL":
            entry["status"] = "FAIL"
        elif status == "INFO" and entry["status"] != "FAIL" \
                and not entry["lines"]:
            entry["status"] = "INFO"
        elif status == "PASS" and entry["status"] == "INFO":
            entry["status"] = "PASS"
        entry["lines"].append("%s %s" % (status, message))
        entry["numbers"].update(numbers)

    def summary(self):
        print("\n%-8s %-6s" % ("CHECK", "STATUS"))
        for check, entry in sorted(self.data.items()):
            print("%-8s %-6s" % (check, entry["status"]))
        n_fail = sum(e["status"] == "FAIL" for e in self.data.values())
        print("\nOVERALL: %s" % ("FAIL (%d check group(s))" % n_fail
                                 if n_fail else "PASS"))
        return n_fail

    def save(self, path):
        def conv(o):
            if isinstance(o, (np.integer,)):
                return int(o)
            if isinstance(o, (np.floating,)):
                return float(o)
            if isinstance(o, np.ndarray):
                return o.tolist()
            return str(o)
        with open(path, "w") as fh:
            json.dump(self.data, fh, indent=1, default=conv)


# --------------------------------------------------------------------------
# file helpers
# --------------------------------------------------------------------------
def find_backup(fixed, backup):
    if backup:
        candidates = [backup]
    else:
        candidates = [fixed + ".bak"] + [fixed + ".bak%d" % n
                                         for n in range(1, 10)]
    for path in candidates:
        if os.path.isfile(path):
            return path
    sys.exit("No backup file found (tried: %s). Use --backup." %
             ", ".join(candidates))


def sorted_locs(tone_group):
    return sorted(tone_group.keys(), key=int)


def concat_data(tone_group, locs, key):
    return np.concatenate([np.atleast_1d(tone_group[l]["data"][key][()])
                           for l in locs])


def same_value(a, b):
    a, b = np.asarray(a), np.asarray(b)
    if a.dtype != b.dtype or a.shape != b.shape:
        return False
    return bool(np.array_equal(a, b, equal_nan=a.dtype.kind == "f"))


def read_iq(tone_group, locs, n_cols):
    """Rows of one tone (loc order) as two (rows, n_cols) int32 arrays."""
    counts = [np.atleast_1d(tone_group[l]["data"]["t0"][()]).shape[0]
              for l in locs]
    out = []
    for key in ("i", "q"):
        arr = np.empty((sum(counts), n_cols), dtype=np.int32)
        pos = 0
        for loc, n in zip(locs, counts):
            arr[pos:pos + n] = np.asarray(
                tone_group[loc]["data"][key][()]).reshape(n, n_cols)
            pos += n
        out.append(arr)
    return out


def load_tone_meta(fo, fn, tone):
    go, gn = fo["tones"][tone], fn["tones"][tone]
    lo, ln = sorted_locs(go), sorted_locs(gn)
    info = go[lo[0]]["info"]
    return {
        "locs_old": lo, "locs_new": ln,
        "t0_old": concat_data(go, lo, "t0").astype(float),
        "t0_new": concat_data(gn, ln, "t0").astype(float),
        "counter": concat_data(go, lo, "counter").astype(np.int64),
        "fs": float(info["fs"][()]),
        "fir_dec": float(info["fir_dec"][()]),
    }


# --------------------------------------------------------------------------
# A. structure
# --------------------------------------------------------------------------
def structure_issues(fo, fn, tone):
    go, gn = fo["tones"][tone], fn["tones"][tone]
    issues = []
    lo, ln = sorted_locs(go), sorted_locs(gn)
    if lo != ln:
        return ["loc sets differ"]
    for loc in lo:
        do, dn = go[loc]["data"], gn[loc]["data"]
        if set(do) != set(dn):
            issues.append("loc %s: data keys differ %s vs %s" %
                          (loc, sorted(do), sorted(dn)))
            continue
        for key in do:
            so, sn = do[key], dn[key]
            if so.dtype != sn.dtype:
                issues.append("loc %s/%s: dtype %s vs %s" %
                              (loc, key, so.dtype, sn.dtype))
            if key in ("i", "q"):
                if not (so.shape[-1] == OLD_COLS and sn.shape[-1] == NEW_COLS
                        and so.shape[:-1] == sn.shape[:-1]):
                    issues.append("loc %s/%s: shape %s -> %s" %
                                  (loc, key, so.shape, sn.shape))
            elif so.shape != sn.shape:
                issues.append("loc %s/%s: shape %s vs %s" %
                              (loc, key, so.shape, sn.shape))
        if "counter" in do and not same_value(do["counter"][()],
                                              dn["counter"][()]):
            issues.append("loc %s: counter differs" % loc)
        io, inn = go[loc]["info"], gn[loc]["info"]
        if set(io) != set(inn):
            issues.append("loc %s: info keys differ" % loc)
        else:
            for key in io:
                if not same_value(io[key][()], inn[key][()]):
                    issues.append("loc %s: info/%s differs" % (loc, key))
    return issues


def check_structure(fo, fn, tones_o, tones_n, rep):
    ok_sets = tones_o == tones_n
    rep.add("A", "PASS" if ok_sets else "FAIL",
            "tone sets %s (%d vs %d tones)" %
            ("identical" if ok_sets else "DIFFER", len(tones_o), len(tones_n)))
    attr = fn.attrs.get("gw_fix_version")
    rep.add("A", "PASS" if attr is not None else "FAIL",
            "root attr gw_fix_version = %s" % attr)
    per_tone = {}
    for tone in sorted(set(tones_o) & set(tones_n)):
        per_tone[tone] = structure_issues(fo, fn, tone)
    bad = {t: v for t, v in per_tone.items() if v}
    rep.add("A", "FAIL" if bad else "PASS",
            "per-tone structure (locs, keys, dtypes, info, counter, "
            "2560->2558): %d/%d tones with issues" % (len(bad), len(per_tone)))
    for tone, issues in list(bad.items())[:5]:
        print("      %s: %s%s" % (tone, "; ".join(issues[:3]),
                                  " ..." if len(issues) > 3 else ""))
    return per_tone


# --------------------------------------------------------------------------
# B. data integrity
# --------------------------------------------------------------------------
def check_integrity_tone(fo, fn, tone):
    go, gn = fo["tones"][tone], fn["tones"][tone]
    keep = np.setdiff1d(np.arange(OLD_COLS), REPEATED)
    res = {"rows": 0, "mismatch_iq": 0, "mismatch_other": 0,
           "rows_bad_rep": 0, "elements": 0}
    for loc in sorted_locs(go):
        do, dn = go[loc]["data"], gn[loc]["data"]
        n_rows = np.atleast_1d(do["t0"][()]).shape[0]
        res["rows"] += n_rows
        for key in do:
            if key in ("i", "q", "t0", "counter"):
                continue
            res["mismatch_other"] += int(not same_value(do[key][()],
                                                        dn[key][()]))
        for start in range(0, n_rows, CHUNK_ROWS):
            sl = slice(start, min(start + CHUNK_ROWS, n_rows))
            bad_rep = np.zeros(sl.stop - sl.start, dtype=bool)
            for key in ("i", "q"):
                old = np.asarray(do[key][()] if do[key].ndim == 1
                                 else do[key][sl]).reshape(-1, OLD_COLS)
                new = np.asarray(dn[key][()] if dn[key].ndim == 1
                                 else dn[key][sl]).reshape(-1, NEW_COLS)
                res["mismatch_iq"] += int(np.count_nonzero(
                    old[:, keep] != new))
                res["elements"] += new.size
                bad_rep |= ((old[:, 5] != old[:, 4]) |
                            (old[:, 6] != old[:, 4]))
            res["rows_bad_rep"] += int(bad_rep.sum())
    return res


# --------------------------------------------------------------------------
# C. repeated samples
# --------------------------------------------------------------------------
def repeat_counts(i, q):
    """Per-lag count of rows where sample k == sample k-1 in both i and q."""
    counts = np.zeros(N_RATE_LAGS)
    for start in range(0, i.shape[0], 1024):
        ic, qc = i[start:start + 1024], q[start:start + 1024]
        for k in range(1, N_RATE_LAGS + 1):
            counts[k - 1] += np.count_nonzero((ic[:, k] == ic[:, k - 1]) &
                                              (qc[:, k] == qc[:, k - 1]))
    return counts


def stream_repeat_counts(i, q, order):
    """Consecutive identical (i, q) pairs in the time-ordered stream."""
    same, total = 0, 0
    last = None
    for start in range(0, len(order), 512):
        rows = order[start:start + 512]
        fi, fq = i[rows].ravel(), q[rows].ravel()
        if last is not None:
            same += int(fi[0] == last[0] and fq[0] == last[1])
            total += 1
        same += int(np.count_nonzero((fi[1:] == fi[:-1]) &
                                     (fq[1:] == fq[:-1])))
        total += fi.size - 1
        last = (fi[-1], fq[-1])
    return same, total


# --------------------------------------------------------------------------
# D / E. timing from metadata
# --------------------------------------------------------------------------
def analyze_timing(m):
    fs, fir_dec = m["fs"], m["fir_dec"]
    fs_clk = fs * fir_dec
    t0o, t0n, cnt = m["t0_old"], m["t0_new"], m["counter"]
    order_o = np.argsort(t0o, kind="stable")
    order_n = np.argsort(t0n, kind="stable")
    r = {"fs": fs, "order_o": order_o, "order_n": order_n,
         "same_order": bool(np.array_equal(order_o, order_n))}
    to, tn = t0o[order_o], t0n[order_n]
    dto, dtn = np.diff(to), np.diff(tn)
    nom_o, nom_n = OLD_COLS / fs, NEW_COLS / fs
    mult = np.rint(dtn / nom_n).astype(int)
    r.update(to=to, tn=tn, dto=dto, dtn=dtn, mult=mult, nom_n=nom_n,
             nom_o=nom_o)
    contig = mult == 1
    r["max_dev_contig"] = float(np.abs(dtn[contig] - nom_n).max()) \
        if contig.any() else 0.0
    r["max_resid"] = float(np.abs(dtn - mult * nom_n).max()) \
        if dtn.size else 0.0
    r["gap_sizes"] = mult[~contig].tolist()
    r["n_nonpositive"] = int(np.count_nonzero(mult < 1))
    # boundary excess = first sample of next row - (last sample + 1/fs)
    r["exc_o"] = dto - OLD_COLS / fs
    r["exc_n"] = dtn - NEW_COLS / fs
    r["n_overlap_o"] = int(np.count_nonzero(r["exc_o"] < -TOL))
    r["n_back_o"] = int(np.count_nonzero(r["exc_o"] <= -1 / fs))
    r["max_overlap_o"] = float(max(0.0, -r["exc_o"].min())) \
        if dto.size else 0.0
    r["n_overlap_n"] = int(np.count_nonzero(r["exc_n"] < -TOL))
    r["n_bad_steps_n"] = int(np.count_nonzero(contig &
                                              (np.abs(r["exc_n"]) > TOL)))
    r["t0_shift"] = (t0o - t0n)[order_o]

    # E: counter-based absolute alignment
    t_start = t0o - cnt / fs_clk
    x = np.empty_like(t0n)
    srt = np.argsort(t_start)
    breaks = np.flatnonzero(np.diff(t_start[srt]) > 1e-3) + 1
    groups = np.split(srt, breaks)
    for idx in groups:
        ts = np.median(t_start[idx])
        tick_last = (t0n[idx] + (NEW_COLS - 1) / fs - ts) * fs_clk
        x[idx] = (cnt[idx] - tick_last) / fir_dec
    r.update(x=x, x_order=x[order_n], n_tstart_groups=len(groups),
             t_start_spread=float(np.ptp(t_start)))
    return r


def group_tones_by_timing(meta):
    groups = {}
    for tone, m in meta.items():
        h = hashlib.md5()
        for key in ("t0_old", "t0_new", "counter"):
            h.update(np.ascontiguousarray(m[key]).tobytes())
        groups.setdefault(h.hexdigest(), []).append(tone)
    return list(groups.values())


def fmt_counts(values, ndigits=5, top=4):
    cnt = Counter(np.round(values, ndigits).tolist())
    return ", ".join("%.5f s x%d" % (v, c) for v, c in
                     sorted(cnt.items(), key=lambda kv: -kv[1])[:top])


def report_timing(tones, r, rep, label):
    fs = r["fs"]
    rep.add("D", "INFO", "%s: %d rows, time order identical old/new: %s" %
            (label, r["to"].size, r["same_order"]))
    if not r["same_order"]:
        rep.add("D", "FAIL", "%s: time order of old and new t0 differ" % label)
    rep.add("D", "INFO", "%s: old dt0 min %.6f max %.6f; %s" %
            (label, r["dto"].min(), r["dto"].max(), fmt_counts(r["dto"])))
    rep.add("D", "INFO", "%s: new dt0 min %.6f max %.6f; %s" %
            (label, r["dtn"].min(), r["dtn"].max(), fmt_counts(r["dtn"])))
    ok = (r["max_dev_contig"] < TOL and r["max_resid"] < TOL
          and r["n_nonpositive"] == 0)
    rep.add("D", "PASS" if ok else "FAIL",
            "%s: new rows spaced by 2558/fs=%.6f s: max |dt-nom| (contiguous)"
            " = %.2e s, max deviation from an integer multiple = %.2e s" %
            (label, r["nom_n"], r["max_dev_contig"], r["max_resid"]))
    gaps = r["gap_sizes"]
    rep.add("D", "INFO", "%s: real gaps: %d; round(dt/nom) = %s, i.e. "
            "missing rows = %s" % (label, len(gaps), gaps[:10],
                                   [g - 1 for g in gaps[:10]]),
            n_gaps=len(gaps), gap_dt_over_nominal=gaps,
            gap_missing_rows=[g - 1 for g in gaps])
    rep.add("D", "INFO", "%s: OLD axis: %d overlapping boundaries (%d going "
            "backwards), largest overlap %.4f s" %
            (label, r["n_overlap_o"], r["n_back_o"], r["max_overlap_o"]),
            n_overlap_old=r["n_overlap_o"], max_overlap_old=r["max_overlap_o"])
    rep.add("D", "PASS" if r["n_bad_steps_n"] == 0 and r["n_overlap_n"] == 0
            else "FAIL",
            "%s: NEW axis: %d non-1/fs steps at contiguous boundaries, %d "
            "overlaps, besides %d real gaps" %
            (label, r["n_bad_steps_n"], r["n_overlap_n"], len(gaps)))


def report_alignment(r, rep, label):
    x = r["x"]
    xmin, xmax = float(x.min()), float(x.max())
    late = float(np.mean(x > 0))
    outside = float(np.mean((x < -256) | (x > 20)))
    if r["n_tstart_groups"] > 1:
        rep.add("E", "INFO", "%s: t_start varies (%d groups, spread %.3g s)"
                % (label, r["n_tstart_groups"], r["t_start_spread"]))
    ok = xmin >= -256 and xmax <= 20 and xmin <= -245
    rep.add("E", "PASS" if ok else "FAIL",
            "%s: x=(counter-tick_last)/fir_dec in samples: min %.2f max %.2f;"
            " rows x>0: %.2f%%; outside [-256,20]: %.2f%% (expected min "
            "about -255, i.e. in [-256,-245]; a t0 misaligned by s samples "
            "shifts everything by s)" %
            (label, xmin, xmax, 100 * late, 100 * outside),
            x_min=xmin, x_max=xmax, frac_late=late, frac_outside=outside)


# --------------------------------------------------------------------------
# F. spectra
# --------------------------------------------------------------------------
def longest_run(contig_mask):
    """(first_row, last_row) of the longest run of True in a diff mask."""
    best, start = (0, 0), None
    for n, flag in enumerate(np.append(contig_mask, False)):
        if flag and start is None:
            start = n
        elif not flag and start is not None:
            if n - start > best[1] - best[0]:
                best = (start, n)
            start = None
    return best[0], best[1]      # rows best[0] .. best[1] inclusive


def welch_blocks(z, fs, nperseg):
    """Welch PSD averaged over blocks of 64 segments (bounded memory)."""
    nperseg = min(nperseg, len(z))
    block = nperseg * 64
    acc, weight = None, 0
    for start in range(0, len(z), block):
        piece = z[start:start + block]
        if len(piece) < nperseg:
            break
        f, p = signal.welch(piece, fs=fs, nperseg=nperseg,
                            return_onesided=False)
        acc = p * len(piece) if acc is None else acc + p * len(piece)
        weight += len(piece)
    return np.fft.fftshift(f), np.fft.fftshift(acc / weight)


def stream(i, q, rows):
    z = (i[rows].astype(np.float64).ravel()
         + 1j * q[rows].astype(np.float64).ravel())
    return (z - z.mean()).astype(np.complex64)


def comb_ratio(f, p, spacing):
    df = f[1] - f[0]
    def band(fc):
        k = int(round((fc - f[0]) / df))
        return p[max(k - 1, 0):k + 2].mean()
    peak = np.array([band(m * spacing) for m in range(1, 11)])
    mid = np.array([band((m + 0.5) * spacing) for m in range(1, 11)])
    return 10 * np.log10(peak / mid)


def spectral_tone(tone, fs, i_old, q_old, i_new, q_new, tm, timing, nperseg):
    order = timing["order_n"]
    mask = np.abs(timing["dtn"] - timing["nom_n"]) < TOL
    first, last = longest_run(mask)
    rows = order[first:last + 1]
    rows_old = timing["order_o"][first:last + 1]
    res = {"tone": tone, "n_rows": len(rows)}
    if len(rows) < 3:
        return res
    zo, zn = stream(i_old, q_old, rows_old), stream(i_new, q_new, rows)
    f, po = welch_blocks(zo, fs, nperseg)
    _, pn = welch_blocks(zn, fs, nperseg)
    spacing = fs / OLD_COLS
    res.update(f=f, po=po, pn=pn,
               comb_old=comb_ratio(f, po, spacing),
               comb_new=comb_ratio(f, pn, spacing), spacing=spacing)
    return res


# --------------------------------------------------------------------------
# plots
# --------------------------------------------------------------------------
def savefig(fig, outdir, name, show):
    path = os.path.join(outdir, name)
    fig.savefig(path, dpi=120)
    if not show:
        import matplotlib.pyplot as plt
        plt.close(fig)
    print("saved", path)
    return path


def plot_timing(r, outdir, show, plt):
    fig, ax = plt.subplots(2, 2, figsize=(13, 8.5), constrained_layout=True)
    n = np.arange(r["to"].size)
    a = ax[0, 0]
    a.plot(n, r["t0_shift"], ".", ms=2, color=C_OLD)
    a.set(title="(a) t0_old - t0_new (rows in time order)",
          xlabel="row (time order)", ylabel="seconds")
    a = ax[0, 1]
    a.plot(n[1:], r["dto"], ".", ms=3, color=C_OLD, label="old")
    a.plot(n[1:], r["dtn"], ".", ms=3, color=C_NEW, label="new")
    lo = min(r["dto"].min(), r["dtn"].min())
    typical = np.median(r["dtn"])
    a.set_ylim(min(lo, typical) - 0.2, typical + 0.5)
    n_off = int(np.count_nonzero(r["dtn"] > typical + 0.5))
    a.set(title="(b) delta t0 between consecutive rows (%d gap(s) off-scale)"
          % n_off, xlabel="row (time order)", ylabel="seconds")
    a.legend(loc="lower right")
    a = ax[1, 0]
    ylim = 1.5
    a.plot(n[1:], np.clip(r["exc_o"], -ylim, ylim), ".", ms=3, color=C_OLD,
           label="old")
    a.plot(n[1:], np.clip(r["exc_n"], -ylim, ylim), ".", ms=3, color=C_NEW,
           label="new")
    a.set(title="(c) row boundary: gap (+) / overlap (-) of the time axis "
          "(clipped at +-%.1f)" % ylim, xlabel="row boundary (time order)",
          ylabel="seconds")
    a.legend(loc="lower right")
    a = ax[1, 1]
    x = r["x"]
    a.axvspan(-255, 0, color="0.85", label="expected window [-255, 0]")
    a.hist(x, bins=np.arange(np.floor(x.min()) - 1, np.ceil(x.max()) + 3, 2),
           color=C_NEW)
    a.set(title="(d) x = (counter - tick_last)/fir_dec", xlabel="samples",
          ylabel="rows")
    a.set_ylim(top=a.get_ylim()[1] * 1.2)
    a.legend(loc="upper left", fontsize=8)
    return savefig(fig, outdir, "timing_overview.png", show)


def plot_repeats(rates, example, outdir, show, plt):
    fig = plt.figure(figsize=(14, 9), constrained_layout=True)
    gs = fig.add_gridspec(3, 3, height_ratios=[1.1, 1, 1])
    a = fig.add_subplot(gs[0, :])
    ks = np.arange(1, N_RATE_LAGS + 1)
    floor = 1e-6
    a.semilogy(ks, np.maximum(rates["old"], floor), "o-", color=C_OLD,
               label="old")
    a.semilogy(ks, np.maximum(rates["new"], floor), "s-", color=C_NEW,
               label="new")
    a.set(title="(a) rate of sample k == sample k-1 (I and Q, mean over rows "
          "and tones; zeros drawn at 1e-6)", xlabel="k", ylabel="rate")
    a.set_xticks(ks)
    a.legend()
    if example is None:
        return savefig(fig, outdir, "repeated_samples.png", show)
    kk = np.arange(14)
    for col, ex in enumerate(example["rows"]):
        for row, key in enumerate(("i", "q")):
            b = fig.add_subplot(gs[1 + row, col])
            shift = ex["t0_old"] - ex["t0_new"]
            t_old = t_new = kk / example["fs"] * 1e3
            b.plot(t_old, ex[key + "_old"][:14], "o-", color=C_OLD, ms=5,
                   label="old")
            rep = list(REPEATED)
            b.plot(t_old[rep], ex[key + "_old"][rep], "o", mfc="none",
                   mec="k", ms=11, label="old samples 5,6 (copies of 4)")
            b.plot(t_new, ex[key + "_new"][:14], "s-", color=C_NEW, ms=4,
                   label="new")
            b.set_xlabel("time since own t0 [ms]")
            b.set_ylabel(key.upper())
            if row == 0:
                b.set_title("%s row %d: t0_old-t0_new = %.3f s" %
                            (example["tone"], ex["row"], shift), fontsize=9)
            if row == 0 and col == 0:
                b.legend(fontsize=8)
    return savefig(fig, outdir, "repeated_samples.png", show)


def plot_psd(spectra, outdir, show, plt):
    spectra = [s for s in spectra if "f" in s]
    if not spectra:
        return None
    fig, ax = plt.subplots(len(spectra), 2, figsize=(14, 3.6 * len(spectra)),
                           constrained_layout=True, squeeze=False)
    for row, s in enumerate(spectra):
        for col in range(2):
            a = ax[row, col]
            for key, color, label in (("po", C_OLD, "old"),
                                      ("pn", C_NEW, "new")):
                a.plot(s["f"], 10 * np.log10(s[key] + 1e-30), color=color,
                       lw=0.8, label=label, alpha=0.85)
            if col == 1:
                a.set_xlim(-1, 1)
                for m in range(-10, 11):
                    a.axvline(m * s["spacing"], color="0.6", lw=0.5, ls=":")
                a.set_title("%s zoom |f|<1 Hz (dotted: multiples of %.4f Hz)"
                            % (s["tone"], s["spacing"]), fontsize=9)
            else:
                a.set_title("%s: PSD of longest contiguous run (%d rows)" %
                            (s["tone"], s["n_rows"]), fontsize=9)
            a.set_xlabel("frequency [Hz]")
            a.set_ylabel("dB (arb.)")
            if row == 0 and col == 0:
                a.legend()
    return savefig(fig, outdir, "psd_comparison.png", show)


def plot_tone_summary(tones, per_tone_x, per_tone_dev, per_tone_issues,
                      outdir, show, plt):
    fig, ax = plt.subplots(3, 1, figsize=(max(8, 0.35 * len(tones) + 3), 9),
                           sharex=True, constrained_layout=True)
    pos = np.arange(len(tones))
    ax[0].bar(pos - 0.2, [per_tone_x[t][0] for t in tones], 0.4,
              color=C_NEW, label="min x")
    ax[0].bar(pos + 0.2, [per_tone_x[t][1] for t in tones], 0.4,
              color=C_OLD, label="max x")
    ax[0].axhspan(-256, 20, color="0.9", zorder=0)
    ax[0].set(ylabel="x [samples]", title="check E per tone (grey: allowed)")
    ax[0].legend(fontsize=8)
    ax[1].bar(pos, [per_tone_dev[t] * 1e6 for t in tones], color=C_NEW)
    ax[1].set(ylabel="max |dt - 2558/fs| [us]",
              title="check D per tone (contiguous rows)")
    ax[2].bar(pos, [len(per_tone_issues.get(t, [])) for t in tones],
              color=C_OLD)
    ax[2].set(ylabel="# issues", title="check A per tone")
    ax[1].set_ylim(0, max(1.0, ax[1].get_ylim()[1]))
    ax[2].set_ylim(0, max(1.0, ax[2].get_ylim()[1]))
    ax[2].set_xticks(pos)
    ax[2].set_xticklabels(tones, rotation=90, fontsize=7)
    return savefig(fig, outdir, "tone_summary.png", show)


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------
def pick_tones(all_tones, requested, full):
    if full:
        return list(all_tones)
    if requested:
        missing = [t for t in requested if t not in all_tones]
        if missing:
            sys.exit("Unknown tones: %s" % ", ".join(missing))
        return list(requested)
    idx = np.unique(np.round(np.linspace(0, len(all_tones) - 1, 4)).astype(int))
    return [all_tones[k] for k in idx]


def heavy_checks(fo, fn, tones, meta, timing_by_tone, args, rep):
    totals = Counter()
    lag_old, lag_new = np.zeros(N_RATE_LAGS), np.zeros(N_RATE_LAGS)
    stream_old, stream_new = [0, 0], [0, 0]
    n_rows_total = 0
    spectra, example = [], None
    for tone in tones:
        res = check_integrity_tone(fo, fn, tone)
        for k, v in res.items():
            totals[k] += v
        status = ("PASS" if res["mismatch_iq"] == 0
                  and res["mismatch_other"] == 0 else "FAIL")
        rep.add("B", status, "%s: %d rows, i/q mismatches vs backup minus "
                "cols 5,6: %d of %d elements; other keys differing: %d; "
                "backup rows with s5/s6 != s4: %d" %
                (tone, res["rows"], res["mismatch_iq"], res["elements"],
                 res["mismatch_other"], res["rows_bad_rep"]))
        m, timing = meta[tone], timing_by_tone[tone]
        i_o, q_o = read_iq(fo["tones"][tone], m["locs_old"], OLD_COLS)
        i_n, q_n = read_iq(fn["tones"][tone], m["locs_new"], NEW_COLS)
        lag_old += repeat_counts(i_o, q_o)
        lag_new += repeat_counts(i_n, q_n)
        n_rows_total += i_o.shape[0]
        for acc, (i, q, order) in ((stream_old, (i_o, q_o, timing["order_o"])),
                                   (stream_new, (i_n, q_n, timing["order_n"]))):
            s, t = stream_repeat_counts(i, q, order)
            acc[0] += s
            acc[1] += t
        spectra.append(spectral_tone(tone, m["fs"], i_o, q_o, i_n, q_n, m,
                                     timing, args.nperseg))
        if example is None and i_o.shape[0] > 5:
            example = {"tone": tone, "fs": m["fs"], "rows": []}
            for row in timing["order_o"][2:5]:
                example["rows"].append({
                    "row": int(row), "t0_old": m["t0_old"][row],
                    "t0_new": m["t0_new"][row], "i_old": i_o[row, :14].copy(),
                    "q_old": q_o[row, :14].copy(),
                    "i_new": i_n[row, :14].copy(),
                    "q_new": q_n[row, :14].copy()})
        del i_o, q_o, i_n, q_n

    ok = totals["mismatch_iq"] == 0 and totals["mismatch_other"] == 0
    rep.add("B", "PASS" if ok else "FAIL",
            "TOTAL %d tones, %d rows: %d i/q mismatches (bit-exact: %s)" %
            (len(tones), totals["rows"], totals["mismatch_iq"], ok),
            mismatches=totals["mismatch_iq"])
    rep.add("B", "INFO", "backup rows violating s5==s6==s4: %d of %d "
            "(%.4f%% conform)" %
            (totals["rows_bad_rep"], totals["rows"],
             100 * (1 - totals["rows_bad_rep"] / max(totals["rows"], 1))),
            rows_violating=totals["rows_bad_rep"])
    # C
    rates = {"old": lag_old / max(n_rows_total, 1),
             "new": lag_new / max(n_rows_total, 1)}
    print("      k   old rate     new rate")
    for k in range(N_RATE_LAGS):
        print("     %2d  %9.5f   %9.5f%s" % (k + 1, rates["old"][k],
                                            rates["new"][k],
                                            "   <- repeated" if k + 1 in
                                            REPEATED else ""))
    chance = float(np.median(rates["new"]))
    old_ok = all(rates["old"][k - 1] >= 0.99 for k in REPEATED)
    new_ok = rates["new"].max() <= max(5 * chance, chance + 0.01)
    rep.add("C", "PASS" if old_ok and new_ok else "FAIL",
            "old rate at k=5,6: %.4f, %.4f (expect ~1); new max rate over "
            "k=1..15: %.4f (chance level, median %.4f)" %
            (rates["old"][4], rates["old"][5], rates["new"].max(), chance),
            rate_old=rates["old"], rate_new=rates["new"])
    rep.add("C", "INFO", "consecutive identical (i,q) pairs in ordered stream:"
            " old %.5f%% (%d/%d), new %.5f%% (%d/%d)" %
            (100 * stream_old[0] / max(stream_old[1], 1), stream_old[0],
             stream_old[1], 100 * stream_new[0] / max(stream_new[1], 1),
             stream_new[0], stream_new[1]))
    # F
    for s in spectra:
        if "f" not in s:
            rep.add("F", "INFO", "%s: longest contiguous run too short "
                    "(%d rows), skipped" % (s["tone"], s["n_rows"]))
            continue
        rep.add("F", "INFO", "%s: %d contiguous rows; comb lines (m*%.4f Hz, "
                "m=1..10) vs mid-bins: old mean %+.2f dB (max %+.2f), new "
                "mean %+.2f dB (max %+.2f)" %
                (s["tone"], s["n_rows"], s["spacing"], s["comb_old"].mean(),
                 s["comb_old"].max(), s["comb_new"].mean(),
                 s["comb_new"].max()))
    return rates, example, spectra


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Check a repaired .gw file against its backup "
                    "(read-only).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Examples" + __doc__.split("Examples")[1])
    ap.add_argument("--fixed", required=True, help="repaired .gw file")
    ap.add_argument("--backup", help="original file (default: FIXED.bak, "
                    "then .bak1, .bak2, ...)")
    ap.add_argument("--tones", nargs="+", help="tones for the heavy data "
                    "checks, plots and PSD (default: up to 4 spread over the "
                    "sorted tone list)")
    ap.add_argument("--full", action="store_true",
                    help="heavy data checks on ALL tones (slow on big files)")
    ap.add_argument("--outdir", default="gw_fix_check",
                    help="output directory for figures and JSON "
                    "(default: ./gw_fix_check)")
    ap.add_argument("--show", action="store_true",
                    help="also display the figures")
    ap.add_argument("--nperseg", type=int, default=2 ** 15,
                    help="Welch segment length (default 32768)")
    args = ap.parse_args(argv)

    import matplotlib
    if not args.show:
        matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    backup = find_backup(args.fixed, args.backup)
    if os.path.abspath(backup) == os.path.abspath(args.fixed):
        sys.exit("fixed and backup are the same file")
    os.makedirs(args.outdir, exist_ok=True)
    print("fixed :", args.fixed)
    print("backup:", backup)
    rep = Reporter()

    with h5py.File(args.fixed, "r") as fn, h5py.File(backup, "r") as fo:
        tones_o, tones_n = sorted(fo["tones"]), sorted(fn["tones"])
        common = sorted(set(tones_o) & set(tones_n))
        per_tone_issues = check_structure(fo, fn, tones_o, tones_n, rep)
        heavy = pick_tones(common, args.tones, args.full)
        print("heavy-check tones (%d): %s" % (len(heavy), " ".join(heavy)))

        meta = {t: load_tone_meta(fo, fn, t) for t in common
                if not per_tone_issues.get(t)}
        if not meta:
            rep.add("A", "FAIL", "no structurally valid tone to analyse")
            rep.summary()
            rep.save(os.path.join(args.outdir, "gw_fix_check_summary.json"))
            return 1
        heavy = [t for t in heavy if t in meta]

        # D and E on all tones, one analysis per distinct timing
        timing_by_tone, per_tone_x, per_tone_dev = {}, {}, {}
        groups = group_tones_by_timing(meta)
        first_timing = None
        for g, tones in enumerate(groups):
            r = analyze_timing(meta[tones[0]])
            first_timing = first_timing or r
            for t in tones:
                timing_by_tone[t] = r
                per_tone_x[t] = (float(r["x"].min()), float(r["x"].max()))
                per_tone_dev[t] = r["max_dev_contig"]
            label = "timing group %d/%d (%d tones: %s%s)" % (
                g + 1, len(groups), len(tones), ",".join(tones[:3]),
                ",..." if len(tones) > 3 else "")
            report_timing(tones, r, rep, label)
            report_alignment(r, rep, label)

        rates, example, spectra = heavy_checks(fo, fn, heavy, meta,
                                               timing_by_tone, args, rep)

    print()
    saved = [plot_timing(first_timing, args.outdir, args.show, plt),
             plot_repeats(rates, example, args.outdir, args.show, plt),
             plot_psd(spectra, args.outdir, args.show, plt),
             plot_tone_summary(sorted(meta), per_tone_x, per_tone_dev,
                               per_tone_issues, args.outdir, args.show, plt)]
    json_path = os.path.join(args.outdir, "gw_fix_check_summary.json")
    n_fail = rep.summary()
    rep.save(json_path)
    print("saved", json_path)
    if args.show:
        plt.show()
    return 1 if n_fail else 0


if __name__ == "__main__":
    sys.exit(main())
