BAWSHA · RFSoC lock-in · fw_version 3 · data audit

# BAWSHA .gw timestamp audit: one sample is tripled at the start of every row

Main file: `/bauscia-nas/data/gw_files/031026.gw` (40 tones × 8836 rows × 2560 samples, fs = 262.144 Hz). Cross-checks on `200826`, `010926`, `130926`, `171026.gw` and on the `config_N.json` files of the run started 2026-09-22. Code references are to BAWSHA commit [b7694f8](https://github.com/Lab5015/BAWSHA/tree/b7694f8969cd28cde4ab71736b7cbee9b1797636). Analysis of 2026-10-19.

2 / 2560samples per row are copies: sample k = 4 is delivered three times (k = 4, 5, 6), in every row of every tone.

9 instead of 10counter blocks of 256 samples between two rows, exactly once every 128 rows (2 × 128 = 256).

−0.977 soverlap in the time axis built as `t0 + k/fs`, 69 times per day; counting samples runs 67.4 s/day ahead of the counter.

t0 ≈ row end`t0` marks the last block of the row, not its first sample: 8.79–9.75 s after the first sample (mean 9.27 s).

## 1. What the file contains and how t0 is made

Each tone stores `i`, `q` (int32, shape rows × 2560), `t0` and `counter` per row. All 40 tones of `031026.gw` share the same `t0` and `counter` arrays, `t0` is strictly increasing, and there are no duplicate rows.

On the RFSoC, a row is 10 DMA transfers of 256 samples (`N_ITER = 10`). After the tenth transfer the server reads the 64-bit hardware counters and writes `t0 = t_start + counter / 122.88e6` ([rf_soc_server.py:436](https://github.com/Lab5015/BAWSHA/blob/b7694f8969cd28cde4ab71736b7cbee9b1797636/rfsoc_control/software/src/simba/rf_soc_server.py#L436)). In the data `t0 − counter/122.88e6` is the same constant for every row (the run start, 2026-09-22 14:24:00 UTC), so `t0` carries exactly the information of the counter.

The counter ([single_counter.vhd](https://github.com/Lab5015/BAWSHA/blob/b7694f8969cd28cde4ab71736b7cbee9b1797636/rfsoc_control/firmware/src/single_counter.vhd#L61-L63)) counts fabric clock cycles and latches the count every 256 accepted samples, at the FIFO input. One block of 256 samples is 256 × 468750 = 1.2·108 ticks = 0.9766 s. Every counter value in the run equals 230 mod 1.2·108, so no sample was ever lost before the FIFO.

## 2. The counter advances by 9 blocks instead of 10, every 128 rows

A row holds 2560 samples, so the counter should advance by 10 blocks per row. In 8766 of 8835 steps it does. In 69 steps it advances by 9 blocks, always exactly 128 rows apart. Over the file, time obtained by counting samples is 67.4 s longer than time obtained from `t0`, which is the same as 2 surplus samples per row (2 × 8835 / fs = 67.4 s).

![Top: counter advance per row, 10 blocks except 69 short steps of 9 blocks every 128 rows. Bottom: cumulative difference between sample-count time and t0, a staircase reaching 67.4 s that follows the line n times 2 over fs.](figures/fig1_counter_steps.png)

**Figure 1 –** Counter behaviour in `031026.gw` (tone rk08_3A; the arrays are identical for all 40 tones). **Top:** counter increment between consecutive rows, in units of 256-sample blocks (1.2·108 ticks of 122.88 MHz). The expected value is 10 blocks for a 2560-sample row; red dots mark the 69 rows where it is 9, at row indices 26, 154, 282, … (period 128). **Bottom:** difference between the elapsed time obtained by counting samples (n · 2560/fs) and the elapsed time from `t0` (counter), in seconds, against row index n. The staircase rises by one block (0.977 s) every 128 rows and follows the dashed line n · 2/fs, which is what 2 surplus samples per row produce. The total is 67.38 s = 69 blocks for this file.

Table – Legend of Figure 1

| Element | Meaning |
| --- | --- |
| blue line (top) | (counter\[n\] − counter\[n−1\]) / 1.2·108: counter advance per row in blocks of 256 samples |
| red dots (top) | short steps of 9 blocks; 69 in the file, exactly every 128 rows |
| blue staircase (bottom) | n · 2560/fs − (t0\[n\] − t0\[0\]): sample-count time minus counter time |
| orange dashed (bottom) | model n · 2/fs (7.63 ms per row): 2 surplus samples in each row |

## 3. In every row, sample 4 appears three times

Checking where the 2 surplus samples are is direct: compare each sample with the previous one, in both I and Q. In every row of every tone, samples k = 4, 5 and 6 are identical. Elsewhere such coincidences happen by chance in 0.5–9 % of rows, depending on the noise level of the tone, and there is no excess at the other DMA transfer boundaries (k = 256, 512, …). There are no repeated full 256-sample blocks and no all-zero blocks.

![Top: first 16 raw I and Q samples of three rows, flat at k = 4 to 6. Middle: rate of identical consecutive samples versus position, 100 percent at k = 5 and 6, about 1 percent elsewhere. Bottom: per tone, 100 percent at k = 5 and 6 for all 40 tones against at most 9 percent elsewhere.](figures/fig2_repeated_samples.png)

**Figure 2 –** The triplicated sample. **Top:** raw I (left) and Q (right) in ADC counts for the first 16 samples of rows 0, 1, 2 of rk08_3A. The shaded band marks k = 4–6, where the three values are identical in I and in Q in every row. **Middle:** percentage of rows in which sample k equals sample k−1 (I and Q both), against k, averaged over all 40 tones (first 400 rows each). The inset zooms on k = 1–30: the rate is 100 % at k = 5 and k = 6 and about 1 % (chance) everywhere else. Violet dotted lines mark the DMA transfer boundaries every 256 samples; they show no excess. **Bottom:** per tone, the smaller of the two rates at k = 5 and k = 6 (red, always 100 %) and the largest rate at any other position (blue, chance level, at most 9 % for the five quiet `nada` channels). Dashed separators group the tones by four, which matches the hardware packing of four lock-ins per DMA channel, so all 10 DMA groups are affected.

Table – Legend of Figure 2

| Element | Meaning |
| --- | --- |
| lines (top) | raw samples of rows 0, 1, 2 (blue, orange, green), ADC counts |
| shaded band (top) | k = 4, 5, 6: identical values |
| blue curve (middle) | rate of “sample k identical to sample k−1”, mean over 40 tones |
| red dots (middle) | k = 5 and k = 6: 100 % |
| violet dotted (middle) | DMA transfer boundaries (k = 256 j) |
| red bars (bottom) | min(rate at k = 5, rate at k = 6) per tone |
| blue bars (bottom) | maximum rate at any other position k, per tone (chance level) |

Table – The same signature in other daily files (tone rk08_3A, all rows)

| File | Rows | Rows with k = 4, 5, 6 identical | Control: k = 1, 2, 3 identical | Short counter steps |
| --- | --- | --- | --- | --- |
| 200826.gw | 10710 | 10710 (100 %) | 0 | 84 |
| 010926.gw | 8953 | 8953 (100 %) | 0 | 70 |
| 130926.gw | 8823 | 8823 (100 %) | 0 | 68 |
| 031026.gw | 8836 | 8836 (100 %) | 0 | 69 |
| 171026.gw | 8941 | 8941 (100 %) | 1 | 70 |

## 4. Whole run: 2558 new samples per file, no losses

The file index N in `config_N.json` and the counter stored inside it give a test that uses only file content. If every file adds S new samples, `256·m_N − S·N` must stay inside a window of 256 samples, where mN is the number of latched blocks. For the run started on 2026-09-22 (230 247 files, every 20th checked, 11 514 files), S = 2558 keeps it inside the window for 26 days. S = 2560 leaves it after 128 files and ends 1750 s away.

The file write times give an independent clock. Their absolute offset does not matter here, only the rate. Taking each day's earliest copy relative to the data (when the writer has caught up), the cadence is 9.75799 s per file, against 2558/fs = 9.75800 s and 2560/fs = 9.76563 s.

Concatenating the counters of all 26 daily files of the run (224 135 rows) shows the same 9-block step every 128 rows, with only these exceptions:

Table – Every counter anomaly in the run of 2026-09-22 → 2026-10-17 (224 135 rows)

| When (UTC) | Counter signature | What the samples show | Effect |
| --- | --- | --- | --- |
| 09-22 15:06–15:26 | 127 rows between short steps | extra triple in `220926.gw` row 336 at k = 1540–1542 = 6·256 + 4…6 | +2 copies |
| 09-27 22:05–22:25 | 127 rows between short steps | extra triple in `280926.gw` row 208 at k = 516–518 = 2·256 + 4…6 | +2 copies |
| 09-28 02:35–02:56 | 127 rows between short steps | extra triples in `280926.gw` row 1806 at k = 1028–1030 = 4·256 + 4…6 and row 1807 at k = 260–262 = 256 + 4…6 | +4 copies |
| 09-30 18:27:54 | steps of 14 and 6 blocks (sum 20) | no missing rows; `300926.gw` row 7664 has its counter read 4 blocks late | `t0` of one row 3.9 s late |

The rare extra triples have the same shape as the regular one, appear in all 10 DMA groups at once, and always sit 4 samples after the start of a DMA transfer inside the row. They are the same defect, triggered when the server re-arms an intra-row transfer late (more than about 4 sample periods, 15 ms). No anomaly points to a lost sample.

![Top: counter minus model for 2558 and 2560 samples per file over the whole run; the 2558 model stays within one block, the 2560 model drifts by about 67 seconds per day. Bottom: file write time residuals, flat for 2558 and drifting for 2560.](figures/fig3_whole_run.png)

**Figure 3 –** Whole-run test on the `config_N.json` files of the run started 2026-09-22 (every 20th file). **Top:** difference between the hardware counter and a model in which each file adds S new samples, (256 · mN − S · N)/fs in seconds, against days since the run start; mN = (counterN − 230)/1.2·108. The blue curve (S = 2558) stays inside one 256-sample block for the whole run; the orange curve (S = 2560, what the row length implies) drifts by −2/fs per file, −67.4 s per day. **Bottom:** the same comparison with the time at which each file was copied to `for_tentacular` (NAS clock) in place of the counter. Faint lines are all files: the writer falls behind during the day by up to about 40 min and catches up at the daily file change, giving the sawtooth. Markers are the per-day minima, where the writer is up to date. A constant clock offset cancels in these residuals; the slope of the minima tells which cadence is real, and the 2558 model is flat.

Table – Legend of Figure 3

| Element | Meaning |
| --- | --- |
| blue (both panels) | model with 2558 new samples per file (2560 − 2 copies) |
| orange (both panels) | model with 2560 new samples per file |
| top panel, y axis | counter minus model, in seconds (one 256-sample block = 0.977 s) |
| bottom panel, faint lines | file copy time minus model, every sampled file (includes writer backlog) |
| bottom panel, dots | per-day minimum of the same quantity (writer up to date) |

## 5. Likely cause: dump.vhd registers tready

The stream path of each DMA group is lock-ins → `stop_if_fifo_full` → counter → `axis_data_fifo` (depth 4096) → `dump` → `axis_subset_converter` (TLAST every 256 beats) → AXI DMA.

In [dump.vhd](https://github.com/Lab5015/BAWSHA/blob/b7694f8969cd28cde4ab71736b7cbee9b1797636/rfsoc_control/firmware/src/dump.vhd#L24-L31) all three outputs are registered, including `s_axi_tready`. The FIFO therefore pops on the *previous* cycle's downstream ready, while the data shown to the DMA is a copy of the FIFO head whether or not it was popped. The two handshakes are decoupled.

The DMA is idle between files for many milliseconds (the server extracts and queues 40 channels and reads the counters), so a few samples wait in the FIFO. When the next transfer is armed, tready rises with the FIFO non-empty, and the head word is accepted three times (Figure 4). Between transfers inside a file the restart is faster than one sample period (3.8 ms), the FIFO is empty, and nothing happens. That matches k = 256 j showing no excess.

```
-- dump.vhd, lines 24–31 (run = '1' branch)
split : process (clk) is
begin
  if rising_edge(clk) then
    if (run = '1') then
      m_axi_tdata  <= s_axi_tdata;
      m_axi_tvalid <= s_axi_tvalid;
      s_axi_tready <= m_axi_tready;  -- registered
    ...
```

![Timing diagram: DMA tready rises at cycle 2, dump s_tready one cycle later; FIFO head A is popped at cycle 3 but the DMA accepts A at cycles 2, 3 and 4, then B and C.](figures/fig4_dump_model.png)

**Figure 4 –** Cycle-by-cycle model of `dump.vhd` (run = '1') between the FIFO and a DMA whose tready rises after an idle period, with three words A, B, C already in the FIFO. Rows from top: DMA tready (input to dump), dump's registered s_axi_tready, FIFO head word, FIFO pop (s-side handshake), dump's valid output data, and words accepted by the DMA. Because s_axi_tready lags m_axi_tready by one cycle, A is accepted at c2 and c3 before the FIFO pops it at c3, and its copy in the output register is accepted again at c4. The DMA receives A A A B C: two surplus copies (red), the same signature as k = 4, 5, 6 in the data. The model is the VHDL's own assignment rules, not a hardware capture.

Table – Legend of Figure 4

| Element | Meaning |
| --- | --- |
| blue traces | logic level of the two tready signals (low/high) |
| light blue boxes | word present on that interface in that cycle |
| light green boxes | word removed from the FIFO in that cycle |
| light red boxes | accepted copies of word A (one real, two surplus) |

Two points for the firmware author to confirm. (1) The triple is at k = 4–6, not k = 0–2. Our reading is that the first four samples of the new row are absorbed downstream of `dump` (converter register slice and DMA S2MM input buffer) before the transfer is armed, and the fifth one is the FIFO head that gets tripled. An ILA on dump's two ports at the start of a file would settle it. (2) The same model predicts the opposite failure: if the DMA drops tready while the FIFO holds data, the popped words in flight are lost (2 words in the model). No anomaly in section 4 points to a loss, consistent with the FIFO being empty when each 256-beat transfer ends.

## 6. Consequences for timestamps

`GwReader.get_IQ` builds the time axis as `t0 + k/fs`, k = 0…2559, row by row ([gw_handler.py:689](https://github.com/Lab5015/BAWSHA/blob/b7694f8969cd28cde4ab71736b7cbee9b1797636/src/rw/gw_handler.py#L689-L714)), and the tutorial states that `t0` is the time of the first sample of the row. Neither assumption holds:

- the counter is read after the row is complete, so `t0` is the time of the last 256-block boundary in the row: 8.79–9.75 s *after* the first sample, a sawtooth with period 128 rows;
- a row spans 2558 sample periods (9.758 s), not 2560, because of the copies;
- the reconstructed rows overlap by 0.977 s at every short step, so the concatenated time axis goes backwards 69 times per day;
- `t0` is taken when the server reads the counter, so a software stall moves it: once in the run (30 Sep 18:27:54 UTC) one row is 3.9 s late.

For PSDs of single rows the effect is small (2 repeated samples out of 2560). For correlations with other instruments, coincidence searches or long coherent analyses it matters: a time offset of about 9.3 s, a 0.08 % rate error if time is taken from sample counts, and periodic jumps.

![Top: for six rows around a short step, true spans and the spans assumed by the reader; reader spans are shifted late by about 9.5 s and two of them overlap. Bottom: t0 minus true first-sample time, a sawtooth between 8.8 and 9.75 s, and the overlap between reconstructed rows, minus 0.977 s every 128 rows.](figures/fig5_reader_time_axis.png)

**Figure 5 –** What the reader reconstructs against the true timing, for `031026.gw` (global file indices 91237–100072 in this run). **Top:** rows 152–157 around the short step 154→155. Blue bars: true time span of each row's 2558 unique samples, from the counter and the file index. Orange bars: span assumed by `get_IQ`, \[t0, t0 + 2560/fs). Black triangles: the stored `t0`, at the end of each true row. The orange bars of rows 154 and 155 overlap by 0.977 s. **Bottom:** over the first 400 rows, `t0` minus the true time of the first sample (blue, a sawtooth between 8.79 and 9.75 s) and the gap between consecutive reconstructed rows, t0\[n\] − (t0\[n−1\] + 2560/fs) (red: 0 except −0.977 s every 128 rows).

Table – Legend of Figure 5

| Element | Meaning |
| --- | --- |
| blue bars (top) | true span of the 2558 unique samples of the row |
| orange bars (top) | span assumed by `get_IQ`: t0 … t0 + 2559/fs |
| black ▼ (top) | stored `t0` |
| blue line (bottom) | t0 − true time of the first sample, seconds |
| red line (bottom) | gap (+) or overlap (−) between consecutive reconstructed rows, seconds |

Table – Meaning of the stored quantities: as documented and as observed

| Quantity | Documented / assumed | Observed |
| --- | --- | --- |
| `t0[n]` | time of the first sample of row n | time of the last 256-block boundary in row n (8.79–9.75 s after the first sample) |
| `counter[n]` | acquisition counter of row n | clock ticks since run start at that block boundary; always 230 + j · 1.2·108 |
| row length | 2560 samples = 9.766 s | 2558 new samples = 9.758 s; sample 4 is repeated at k = 5, 6 |
| `t0[n+1] − t0[n]` | 9.766 s | 9.766 s, or 8.789 s once every 128 rows |

## 7. Suggested fixes and a workaround for existing data

### Firmware

Make `dump` a correct AXI-Stream stage: either a plain pass-through when `run = '1'`, or a standard pipeline register with a combinational ready.

```
-- pipeline register with combinational ready (sketch, not tested)
s_axi_tready <= '1' when run = '0' else (not tvalid_r) or m_axi_tready;
process (clk) begin
  if rising_edge(clk) then
    if run = '0' then
      tvalid_r <= '0';
    elsif (not tvalid_r or m_axi_tready) = '1' then   -- empty, or emptied this cycle
      tvalid_r <= s_axi_tvalid;
      tdata_r  <= s_axi_tdata;
    end if;
  end if;
end process;
m_axi_tvalid <= tvalid_r;  m_axi_tdata <= tdata_r;
```

### Server software

Store the time of the first sample of the row. After the firmware fix, one option is to keep a running count of delivered samples per group and set `t0 = t_start + (τ0 + 468750 · ndelivered)/122.88e6`, using the latched counter only as a cross-check. Another is to latch the counter at the first beat of each DMA packet in the firmware. Either way, the tutorial and the reader should state what `t0` means.

### Reading the existing files (fw_version 3)

For files of the run started on 2026-09-22 the relation is exact, so the true timing can be recovered from the stored counter alone. Drop samples k = 5 and 6 of each row, then compute the first-sample time from the counter and the global file index:

```
m = (counter - 230) // 120_000_000                 # latched 256-sample blocks since run start
N = np.floor(256 * m / 2558).astype(int) - 1       # global file index: smallest N with
for _ in range(3):                                 #   floor(2558*(N+1)/256) == m
    N = np.where(np.floor(2558 * (N + 1) / 256) < m, N + 1, N)
t_first = t0 - (256 * m - 1 - 2558 * N) / fs       # time of sample k = 0 of each row
iq = np.delete(i_or_q, [5, 6], axis=1)             # 2558 unique samples
t  = t_first[:, None] + np.arange(2558)[None, :] / fs
```

Checked on `031026.gw`: the inverted N matches the `config_N.json` file names (first row = 91237, last = 100072). The constant 2558 in the inversion holds from 2026-09-28 03:00 UTC to the end of this run. Before that, the extra triples of section 4 shift it by a few samples (a few ms of time). Other runs restart N at 0 and need the same check against their `config_N.json`. To remove the rare extra triples as well, drop any sample that equals the previous one in I and Q in all four lock-ins of its DMA group at once; that test has no false hits outside the five identical `nada` channels.

## 8. Side note: NAS clock

The NAS clock is about 1 h 57 min 40 s ahead of an NTP-synchronised host (HTTP Date header 14:33:48 GMT against 12:36:10 UTC). The RFSoC and the temperature logger agree with real UTC. This does not affect the content of the files, only their modification times. NAS file dates should not be used as time references until its NTP source is fixed.

## Reproduce

Scripts in `/home/comsol/data-analysis/scripts/`, run with `/home/comsol/data-analysis/venv/bin/python`:

Table – Analysis scripts

| Script | What it does |
| --- | --- |
| check_timestamps.py FILE | per-tone monotonicity, duplicates, Δt0, Δcounter, t0 − counter/clock |
| step_pattern.py FILE | positions and period of the short counter steps |
| dup_blocks.py FILE TONE R0 R1 | search for repeated 256-sample blocks and all-zero blocks |
| repeated_samples.py / repeat_stats.py | consecutive identical samples per position and tone |
| json_timeline.py DIR OUT STEP | (N, t0, counter, write time) table from config_N.json |
| daily_files.py DIR | first/last t0 and short-step count of every daily .gw file |
| make_figures.py FILE RESULTS FIGS | Figures 1–5, including the dump.vhd cycle model |