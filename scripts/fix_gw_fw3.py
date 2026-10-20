#!/usr/bin/env python
"""Repair .gw files recorded with firmware v3 (dump.vhd handshake bug).

Firmware v3 delivered, in every 2560-sample row, sample 4 three times
(samples 4, 5, 6 are identical): a row holds only 2558 real samples. The stored
t0 was the time of the *last* 256-sample block boundary of the row (about 9 s
after the first sample), not the time of its first sample.

This script, for every selected .gw file:
  1. backs the original file up (the original is never modified or deleted),
  2. removes samples 5 and 6 of every row (copies of sample 4) from i, q (and
     any other per-row array with 2560 samples),
  3. rebuilds t0 as the time of the first sample of each row, from the row
     sequence (see infer_row_times); the raw `counter` is kept untouched,
  4. writes the fixed file in place of the original (via a temporary file) and
     a JSON report next to it.

Rows are 2558 real samples afterwards, so t0 + k/fs (k = 0..2557) is the time
of sample k and consecutive rows are exactly contiguous.

Examples
--------
  fix_gw_fw3.py --file test/200826.gw
  fix_gw_fw3.py --folder /bauscia-nas/data/gw_files
  fix_gw_fw3.py --list files.txt --folder /bauscia-nas/data/gw_files
  fix_gw_fw3.py --folder data/ --dry-run        # analysis only, nothing written
"""

import argparse
import datetime
import glob
import json
import os
import shutil
import sys
import traceback

import h5py
import numpy as np

FIX_VERSION = 1
ROW_RAW = 2560          # samples per row stored in v3 files
DROP = (5, 6)           # copies of sample 4 (samples 4, 5, 6 are identical)
ROW_SAMPLES = ROW_RAW - len(DROP)  # 2558 real samples per row
BLOCK_SAMPLES = 256     # the hardware counter latches every 256 samples
MIN_STABLE_ROWS = 3     # rows needed to accept a change of row-index offset
TS_TOL = 1e-3           # s, tolerance to group rows of the same run (t_start)


# --------------------------------------------------------------------------
# timing model
# --------------------------------------------------------------------------
def infer_row_times(t0, counter, fir_dec, fs):
    """Time of the first sample of every row, from the stored t0 and counter.

    Model (firmware v3, after removing the 2 copies): the hardware counts
    accepted samples; the n-th sample of a run (n = 0, 1, ...) is accepted at
    clock tick  c_off + (n + 1) * fir_dec  and the counter latches the tick of
    every 256th sample. Rows hold 2558 real samples, so row N (N = 0, 1, ... in
    the run) starts at sample 2558 * N. The stored counter of a row is
    c_off + 256 * m * fir_dec with m = floor(2558 * (N + 1) / 256) when read
    promptly; it can be one or more blocks higher when the server read it late.

    The row index N is recovered from m, and rows must be consecutive, so late
    reads (isolated rows whose m disagrees with their neighbours) are detected
    and do not affect the result: the time of row N is computed from N alone,
        t_first = t_start + (c_off + (2558 * N + 1) * fir_dec) / fs_clk
    with t_start = t0 - counter / fs_clk (constant within a run).

    Parameters
    ----------
    t0, counter : 1D arrays, storage order (may be unsorted in time)
    fir_dec : ticks per sample; fs : sample rate in Hz (fs_clk = fs * fir_dec)

    Returns
    -------
    t_first : 1D array, storage order
    info : dict with diagnostics (per-row arrays are in storage order)
    """
    t0 = np.asarray(t0, dtype=np.float64)
    counter = np.asarray(counter, dtype=np.int64)
    n = len(t0)
    fir_dec = int(round(fir_dec))
    fs_clk = float(round(fs * fir_dec))
    block_ticks = BLOCK_SAMPLES * fir_dec

    order = np.argsort(t0, kind="stable")           # time order
    t0_s, c_s = t0[order], counter[order]
    t_start_row = t0_s - c_s / fs_clk
    run_id = np.concatenate(([0], np.cumsum(np.abs(np.diff(t_start_row)) > TS_TOL)))

    t_first_s = np.empty(n)
    dm_s = np.zeros(n, dtype=np.int64)              # measured - model block count
    flag_s = np.zeros(n, dtype=np.int8)             # 0 ok, 1 late read, 2 other
    row_index_s = np.zeros(n, dtype=np.int64)       # N (row index in its run)
    run_notes = []

    for r in np.unique(run_id):
        sel = np.where(run_id == r)[0]
        c = c_s[sel]
        L = len(sel)
        c_off = int(np.median(c % block_ticks))
        m = (c - c_off) // block_ticks
        t_start = float(np.median(t_start_row[sel]))

        # row index from the block count: floor(R*(N+1)/256) == m
        Np1 = -((-BLOCK_SAMPLES * m) // ROW_SAMPLES)         # ceil(256 m / R)
        valid = ROW_SAMPLES * Np1 < BLOCK_SAMPLES * (m + 1)
        ordinal = np.arange(L)
        n_val = np.where(valid, Np1 - 1 - ordinal, 0)        # N - ordinal

        # consensus offset: accept an offset only if >= MIN_STABLE_ROWS valid
        # rows in a row share it; isolated disagreeing rows are outliers.
        vi = np.where(valid)[0]
        offset = np.full(L, np.iinfo(np.int64).min)
        stable_found = False
        if len(vi):
            vals = n_val[vi]
            brk = np.concatenate(([0], np.where(np.diff(vals) != 0)[0] + 1, [len(vals)]))
            for a, b in zip(brk[:-1], brk[1:]):
                if b - a >= MIN_STABLE_ROWS:
                    offset[vi[a:b]] = vals[a]
                    stable_found = True
        uncertain = False
        if not stable_found:
            uncertain = True
            if len(vi):                                      # most common value
                v, cnt = np.unique(n_val[vi], return_counts=True)
                offset[vi] = v[np.argmax(cnt)]
            else:                                            # approximate fallback
                offset[:] = np.rint(BLOCK_SAMPLES * m[0] / ROW_SAMPLES) - 1
        cur = None
        for k in range(L):                                   # forward fill
            if offset[k] != np.iinfo(np.int64).min:
                cur = offset[k]
            elif cur is not None:
                offset[k] = cur
        first = offset[offset != np.iinfo(np.int64).min][0]
        offset[offset == np.iinfo(np.int64).min] = first     # leading rows

        N = ordinal + offset
        m_model = (ROW_SAMPLES * (N + 1)) // BLOCK_SAMPLES
        dm = m - m_model
        t_first_s[sel] = t_start + (c_off + (ROW_SAMPLES * N + 1) * fir_dec) / fs_clk
        dm_s[sel] = dm
        flag_s[sel] = np.where(dm == 0, 0, np.where(dm > 0, 1, 2))
        row_index_s[sel] = N
        seg_starts = np.concatenate(([0], np.where(np.diff(offset) != 0)[0] + 1))
        run_notes.append(
            dict(
                rows=int(L),
                t_start=t_start,
                c_off=c_off,
                first_row_index=int(N[0]),
                segments=[(int(s), int(N[s])) for s in seg_starts],
                late_read_rows=int(np.sum(dm > 0)),
                other_anomaly_rows=int(np.sum(dm < 0)),
                uncertain=bool(uncertain),
            )
        )

    t_first = np.empty(n)
    dm = np.empty(n, dtype=np.int64)
    flag = np.empty(n, dtype=np.int8)
    ridx = np.empty(n, dtype=np.int64)
    t_first[order], dm[order], flag[order], ridx[order] = t_first_s, dm_s, flag_s, row_index_s
    info = dict(
        runs=run_notes,
        dm=dm,
        flag=flag,
        row_index=ridx,
        n_unsorted=int(np.sum(np.diff(t0) < 0)),
    )
    return t_first, info


# --------------------------------------------------------------------------
# helpers on the gw structure
# --------------------------------------------------------------------------
def sorted_locs(group):
    return sorted(group.keys(), key=int)


def read_rows(fin, tone):
    """t0, counter (storage order) and the list of (loc, n_rows) of a tone."""
    locs = sorted_locs(fin["tones"][tone])
    t0, cnt, layout = [], [], []
    for loc in locs:
        d = fin["tones"][tone][loc]["data"]
        a = np.atleast_1d(d["t0"][()])
        b = np.atleast_1d(d["counter"][()])
        t0.append(a)
        cnt.append(b)
        layout.append((loc, len(a)))
    return np.concatenate(t0), np.concatenate(cnt), layout


def tone_info(fin, tone):
    loc = sorted_locs(fin["tones"][tone])[0]
    inf = fin["tones"][tone][loc]["info"]
    out = {}
    for k in ("fir_dec", "fs", "fw_version"):
        out[k] = float(inf[k][()]) if k in inf else None
    return out


def triple_fraction(fin, tone, max_rows=300):
    """Fraction of (the first max_rows) rows with samples 4, 5, 6 identical."""
    locs = sorted_locs(fin["tones"][tone])
    best = max(locs, key=lambda l: np.atleast_1d(fin["tones"][tone][l]["data/t0"][()]).size)
    d = fin["tones"][tone][best]["data"]
    i = np.atleast_2d(d["i"][:max_rows, :8] if d["i"].ndim == 2 else d["i"][:8])
    q = np.atleast_2d(d["q"][:max_rows, :8] if d["q"].ndim == 2 else d["q"][:8])
    ok = (i[:, 4] == i[:, 5]) & (i[:, 5] == i[:, 6]) & (q[:, 4] == q[:, 5]) & (q[:, 5] == q[:, 6])
    return float(np.mean(ok))


def cut(arr):
    """Remove the repeated samples (last axis)."""
    return np.concatenate((arr[..., : DROP[0]], arr[..., DROP[-1] + 1 :]), axis=-1)


def free_backup_name(path, backup_dir=None):
    base = os.path.join(backup_dir or os.path.dirname(os.path.abspath(path)), os.path.basename(path))
    cand, k = base + ".bak", 0
    while os.path.exists(cand):
        k += 1
        cand = f"{base}.bak{k}"
    return cand


def write_fixed_file(fin, fout, new_t0, layouts, stats):
    """Copy fin to fout applying the fix to every tone."""
    for k, v in fin.attrs.items():
        fout.attrs[k] = v
    for key in fin.keys():
        if key != "tones":
            fin.copy(key, fout)
    gt = fout.create_group("tones")
    for tone in fin["tones"]:
        gtone = gt.create_group(tone)
        pos = 0
        for loc, nrows in layouts[tone]:
            src = fin["tones"][tone][loc]
            gl = gtone.create_group(loc)
            fin.copy(src["info"], gl, name="info")
            gd = gl.create_group("data")
            t_loc = new_t0[tone][pos : pos + nrows]
            pos += nrows
            for key in src["data"]:
                d = src["data"][key]
                if key == "t0":
                    val = t_loc if d.shape != () else t_loc[0]
                    gd.create_dataset("t0", data=np.asarray(val, dtype=d.dtype))
                    continue
                if key != "counter" and d.ndim >= 1 and d.shape[-1] == ROW_RAW:
                    arr = cut(d[()])
                    kw = {}
                    if d.compression is not None and arr.ndim >= 2:
                        kw = dict(compression=d.compression, compression_opts=d.compression_opts,
                                  chunks=True)
                    gd.create_dataset(key, data=arr, **kw)
                else:
                    fin.copy(d, gd, name=key)
        # exact triple statistic over ALL rows, computed from the source
        stats[tone]["triple_rows_ok"], stats[tone]["triple_rows"] = _triple_all(fin, tone)
        print(f"    {tone}: {sum(n for _, n in layouts[tone])} rows written", flush=True)


def _triple_all(fin, tone):
    ok = tot = 0
    for loc in sorted_locs(fin["tones"][tone]):
        d = fin["tones"][tone][loc]["data"]
        i = np.atleast_2d(d["i"][..., :8])
        q = np.atleast_2d(d["q"][..., :8])
        good = (i[:, 4] == i[:, 5]) & (i[:, 5] == i[:, 6]) & (q[:, 4] == q[:, 5]) & (q[:, 5] == q[:, 6])
        ok += int(good.sum())
        tot += len(good)
    return ok, tot


# --------------------------------------------------------------------------
# one file
# --------------------------------------------------------------------------
def fix_file(path, args):
    path = os.path.abspath(path)
    print(f"\n=== {path}  ({os.path.getsize(path) / 1e6:.0f} MB)")
    with h5py.File(path, "r") as fin:
        if "tones" not in fin:
            raise RuntimeError("no /tones group, not a gw data file")
        if "gw_fix_version" in fin.attrs and not args.force:
            print("  already fixed (gw_fix_version attribute present): skipped")
            return "skipped"
        tones = list(fin["tones"].keys())

        # ---- safety checks -------------------------------------------------
        # hard check, not bypassed by --force: removing columns from rows that
        # are not 2560 samples long would delete good samples
        for t in tones:
            for loc in sorted_locs(fin["tones"][t]):
                n_samp = fin["tones"][t][loc]["data/i"].shape[-1]
                if n_samp != ROW_RAW:
                    raise RuntimeError(
                        f"{t}/{loc}: rows have {n_samp} samples, not {ROW_RAW}: "
                        "the file is already fixed or is not a firmware-v3 file")
        infos = {t: tone_info(fin, t) for t in tones}
        fw = {v["fw_version"] for v in infos.values()}
        if any(f is not None and f >= 4 for f in fw) and not args.force:
            print(f"  fw_version {sorted(fw)}: new-firmware data do not need the fix, skipped")
            return "skipped"
        fr = {t: triple_fraction(fin, t) for t in tones}
        worst = min(fr.values())
        print(f"  rows with samples 4=5=6 (sample of first rows): min {worst:.3f}, "
              f"mean {np.mean(list(fr.values())):.3f} over {len(tones)} tones")
        if worst < args.min_triple_frac and not args.force:
            raise RuntimeError(
                f"only {worst:.3f} of the rows show the repeated samples (< {args.min_triple_frac}): "
                "this does not look like firmware-v3 data; use --force to fix anyway")

        # ---- timing --------------------------------------------------------
        new_t0, layouts, stats = {}, {}, {}
        for t in tones:
            t0, cnt, layout = read_rows(fin, t)
            fir_dec = infos[t]["fir_dec"] or 468750
            fs = infos[t]["fs"] or 262.144
            tf, inf = infer_row_times(t0, cnt, fir_dec, fs)
            new_t0[t], layouts[t] = tf, layout
            shift = t0 - tf
            stats[t] = dict(
                n_rows=int(len(t0)),
                n_locs=len(layout),
                triple_fraction_sample=fr[t],
                t0_shift_s=dict(min=float(shift.min()), max=float(shift.max()), mean=float(shift.mean())),
                runs=inf["runs"],
                late_read_rows=[int(i) for i in np.where(inf["flag"] == 1)[0]],
                other_anomaly_rows=[int(i) for i in np.where(inf["flag"] == 2)[0]],
                storage_not_time_ordered=inf["n_unsorted"],
            )
        t = tones[0]
        run0 = stats[t]["runs"][0]
        print(f"  timing ({t}): {stats[t]['n_rows']} rows, {len(stats[t]['runs'])} run(s), "
              f"first row index {run0['first_row_index']}, row-index segments {run0['segments'][:4]}")
        print(f"  t0 shift (old - new first-sample time): {stats[t]['t0_shift_s']['min']:.3f} .. "
              f"{stats[t]['t0_shift_s']['max']:.3f} s;  late counter reads: {len(stats[t]['late_read_rows'])} rows;"
              f" other anomalies: {len(stats[t]['other_anomaly_rows'])} rows")
        if any(s["other_anomaly_rows"] or any(r["uncertain"] for r in s["runs"]) for s in stats.values()):
            print("  WARNING: counter anomalies / uncertain runs found, see the report")

        if args.dry_run:
            print("  dry run: nothing written")
            return "dry-run"

        # ---- write the fixed file -------------------------------------------
        free = shutil.disk_usage(os.path.dirname(path)).free
        if free < 1.1 * os.path.getsize(path):
            raise RuntimeError(f"not enough free disk space ({free / 1e9:.1f} GB) for a temporary copy")
        tmp = path + ".fixing"
        if os.path.exists(tmp):
            os.remove(tmp)
        try:
            with h5py.File(tmp, "w") as fout:
                write_fixed_file(fin, fout, new_t0, layouts, stats)
                fout.attrs["gw_fix_version"] = FIX_VERSION
                fout.attrs["gw_fix_date"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
                fout.attrs["gw_fix_description"] = (
                    "fw3 repair: samples 5,6 of every row removed (copies of sample 4); "
                    "t0 = time of the first sample of the row, rebuilt from the row sequence")
        except BaseException:
            if os.path.exists(tmp):
                os.remove(tmp)
            raise

    # ---- sanity check of the temporary file, then swap files -----------------
    with h5py.File(tmp, "r") as chk:
        for t in tones:
            for loc, nrows in layouts[t]:
                d = chk["tones"][t][loc]["data"]
                assert d["i"].shape[-1] == ROW_SAMPLES and d["q"].shape[-1] == ROW_SAMPLES
                assert np.atleast_1d(d["t0"][()]).size == nrows
    bak = free_backup_name(path, args.backup_dir)
    shutil.move(path, bak)                   # original kept untouched as backup
    try:
        os.replace(tmp, path)
    except BaseException:
        shutil.move(bak, path)               # put the original back
        raise
    rep = path + ".fixlog.json"
    with open(rep, "w") as f:
        json.dump(dict(file=path, backup=bak, fix_version=FIX_VERSION,
                       date=datetime.datetime.now().isoformat(), tones=stats), f, indent=1)
    print(f"  fixed. backup: {bak}\n  report: {rep}")
    return "fixed"


# --------------------------------------------------------------------------
def collect_files(args):
    if args.file:
        return [args.file]
    if args.folder and not args.list:
        return sorted(glob.glob(os.path.join(args.folder, "*.gw")))
    base = args.folder or os.path.dirname(os.path.abspath(args.list))
    names = []
    with open(args.list) as f:
        for line in f:
            line = line.split("#")[0].strip()
            if line:
                names.append(line if os.path.isabs(line) else os.path.join(base, line))
    return names


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", help="a single .gw file")
    ap.add_argument("--folder", help="fix all *.gw files in this folder; with --list, the folder the names are relative to")
    ap.add_argument("--list", help="text file with one .gw file name (or path) per line")
    ap.add_argument("--backup-dir", help="where to put the backups (default: next to each file, as <name>.gw.bak)")
    ap.add_argument("--dry-run", action="store_true", help="analyse only, write nothing")
    ap.add_argument("--force", action="store_true",
                    help="also process files that look fixed / are not firmware v3 / lack the repeated samples")
    ap.add_argument("--min-triple-frac", type=float, default=0.99,
                    help="refuse files where fewer rows show samples 4=5=6 (default 0.99)")
    args = ap.parse_args(argv)
    if not (args.file or args.folder or args.list):
        ap.error("give --file, --folder or --list")
    if args.file and (args.folder or args.list):
        ap.error("--file cannot be combined with --folder/--list")

    files = collect_files(args)
    if not files:
        print("no .gw files found")
        return 1
    print(f"{len(files)} file(s) to process" + ("  [dry run]" if args.dry_run else ""))
    results = {}
    for p in files:
        try:
            results[p] = fix_file(p, args)
        except Exception as e:
            traceback.print_exc()
            print(f"  FAILED: {e}")
            results[p] = "FAILED"
    print("\nsummary:")
    for p, r in results.items():
        print(f"  {r:8s} {p}")
    return 0 if all(r != "FAILED" for r in results.values()) else 2


if __name__ == "__main__":
    sys.exit(main())
