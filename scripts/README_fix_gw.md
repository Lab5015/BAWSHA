# Fixing firmware-v3 `.gw` files

Two scripts to repair and verify `.gw` data recorded with firmware v3.

**The problem in v3 data**
- In every row (2560 samples) sample 4 is delivered three times: samples 4, 5, 6 are identical, so a row holds only **2558 real samples**.
- The stored `t0` is the time of the *end* of the row (8.8–9.8 s after its first sample), not of its first sample. Built as `t0 + k/fs`, the time axis drifts and overlaps by 0.977 s every 128 rows.

Data from the new firmware (`fw_version` 4) does not have these problems and must **not** be fixed.

Requirements: Python with `h5py`, `numpy`, `scipy`, `matplotlib`.

---

## 1. `fix_gw_fw3.py` – repair

What it does for each file:
1. keeps the original, untouched, as a backup `<name>.gw.bak` (`.bak1`, `.bak2`... if that name exists);
2. removes samples 5 and 6 of every row (copies of sample 4) from `i`, `q`;
3. rewrites `t0` as the time of the **first sample** of each row; `counter` and all metadata are left as they are;
4. writes the fixed file in place of the original (through a temporary file) and a report `<name>.gw.fixlog.json`.

After the fix a row has 2558 samples and `t0 + k/fs` (k = 0..2557) is the time of sample k; consecutive rows are exactly contiguous.

Choose **one** way to select the files:

| Option | Meaning |
|---|---|
| `--file F.gw` | a single file |
| `--folder DIR` | all `*.gw` files in `DIR` |
| `--list names.txt` | file names (or paths), one per line, `#` comments allowed; names are relative to `--folder` if given, otherwise to the folder of the list |

Other options: `--dry-run` (analyse only, write nothing), `--backup-dir DIR` (put the backups elsewhere), `--force`, `--min-triple-frac X` (default 0.99).

```
python scripts/fix_gw_fw3.py --dry-run --file run.gw        # look first
python scripts/fix_gw_fw3.py --file run.gw
python scripts/fix_gw_fw3.py --folder /data/gw_files
python scripts/fix_gw_fw3.py --list files.txt --folder /data/gw_files
```

Safety: files already fixed, files with `fw_version` ≥ 4 and files where fewer than 99% of the rows show the repeated samples are skipped or refused. Rows that are not 2560 samples long are always refused, even with `--force`, so a file cannot be fixed twice. A failing file does not stop the others. You need free disk space for a temporary copy of each file (about its size).
Takes about 2 minutes for a 2 GB file.

---

## 2. `check_gw_fix.py` – verify (read-only)

Compares the fixed file with its backup and shows that the fix is correct.

```
python scripts/check_gw_fix.py --fixed run.gw                    # backup = run.gw.bak
python scripts/check_gw_fix.py --fixed run.gw --backup orig.gw --tones rk08_3A tb_5C20
python scripts/check_gw_fix.py --fixed run.gw --full --outdir check_run
```

Options: `--backup` (default `<fixed>.bak`, then `.bak1`...), `--tones` (tones for the heavy checks and plots; default: 4 spread over the file), `--full` (heavy checks on all tones, a few minutes), `--outdir` (default `./gw_fix_check`), `--show` (also display the figures).

Checks (each printed as PASS / FAIL / INFO; exit code 1 if any FAIL):

| | Check |
|---|---|
| A | same tones, groups, keys, metadata and `counter`; `i`,`q` 2560 → 2558 samples |
| B | fixed data are **bit-identical** to the backup with samples 5, 6 removed; those two were copies of sample 4 |
| C | rate of "sample k = sample k−1": 100% at k = 5, 6 before, chance level after |
| D | new rows spaced by exactly 2558/fs = 9.757996 s, no overlaps, real gaps in the data listed; old axis overlaps counted |
| E | independent check of the absolute alignment of the new `t0` using the hardware `counter`: x = (counter − time of last sample)/sample must lie in [−255, +few] samples (min ≈ −250) |
| F | PSD of old vs new stream (INFO only) |

Output in `--outdir`: `timing_overview.png` (old/new `t0` offset, row spacing, overlaps, check-E histogram), `repeated_samples.png`, `psd_comparison.png`, `tone_summary.png` and `gw_fix_check_summary.json`.

---

## Typical use

```
python scripts/fix_gw_fw3.py --dry-run --folder DIR     # 1. what would happen
python scripts/fix_gw_fw3.py --folder DIR               # 2. fix (backups are kept)
python scripts/check_gw_fix.py --fixed DIR/run.gw       # 3. verify one file
```
Delete the `.bak` files only after the check is OK.

## Limits
- The rare *extra* triples elsewhere in a row (a few events in the whole September run, from late DMA re-arms) are not removed: removing them would make rows uneven. Rows after such an event can have timestamps off by 2 samples (about 8 ms); the report lists rows with counter anomalies.
- Row times are exact if the rows of a file are consecutive acquisitions; gaps and restarts are detected and handled.
