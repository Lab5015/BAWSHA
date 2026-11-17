> Migrated from the SimBa repository (2026-11-16). Paths in this note are the old SimBa ones.
> In BAWSHA: `lockin/main.tcl` is `bd/main.tcl`, `lockin/lockin.tcl` is `bd/lockin.tcl`,
> `patch_*.tcl` are in this `docs/` folder. `patch_main_bd.tcl` is already folded into `bd/main.tcl`.
> `patch_lockin_bd.tcl` (DSP reduction) is unverified and not applied.

# Firmware stability changes (branch `software`, firmware v3)

Nothing was run in Vivado. HDL was simulated with GHDL only; the Tcl was only syntax-checked (`info complete`).
`lockin/main.tcl` is **git-ignored** (`firmware/lockin/` is in `.gitignore`), so there is no git copy of the old version.

## 1. `src/dump.vhd` – AXI-Stream handshake fixed (the repeating-samples bug)
- **Old:** `s_axi_tready <= m_axi_tready` was registered, while `tdata/tvalid` were registered every clock without
  checking if the upstream beat was accepted. Every time the DMA lowered `tready` (e.g. between DMA transfers) one
  256-bit beat was lost and the next was delivered 2-3 times (all 4 lanes of a group repeated together).
- **New:** purely combinational gate. `run=1`: transparent (`tdata/tvalid/tready` passed through).
  `run=0`: `s_axi_tready=1`, `m_axi_tvalid=0`, `m_axi_tdata=0` -> still drains/clears the FIFO as before.
- Ports unchanged (BD module reference needs no change).
- Test: `test/tbs/tb_dump.vhd` (source -> dump -> sink with 50% random back-pressure): 1502 beats, 0 duplicates/losses;
  after `run=0` the source is drained and `tvalid` stays low.

## 2. `src/avg12.vhd` (new) – ADC front-end averaging instead of dropping 11 of 12 samples
- The RFDC gives 12 samples/clock (1.47456 GS/s / 122.88 MHz). Before, the BD sliced `adc_data[15:0]` (sample 0 only),
  which folds noise around k*122.88 MHz into the <20 MHz band.
- Now a 12-tap boxcar + decimate-by-12: `out = round(sum12 * 5461/65536)`. Nulls exactly at k*122.88 MHz,
  ~-17 dB at k*122.88 +-20 MHz, DC gain 1, droop ~-0.4 dB at 20 MHz, ~+5 dB SNR on uncorrelated noise.
  4-cycle pipeline (adder tree + 1 DSP), `data_valid_out` is `adc_data_valid` delayed by 4 clocks. Same 16-bit scale.
- Test: `test/tbs/tb_avg12.vhd`: 40 words incl. full-scale +-, 0 errors vs reference model.
- To go back to the old behaviour: in each ADC hierarchy replace `avg12_0` with the old `xlslice_0` (DIN 191:0 -> 15:0)
  and connect the raw `adc_data_valid`.

## 3. `lockin/main.tcl`
- **avg12 inserted** in `adc_224_0`, `adc_224_1`, `adc_226_0` (replaces `xlslice_0`; clock = hierarchy `clk`;
  delayed valid goes to the groups). `avg12` added to the module check list and an `add_files src/avg12.vhd`
  step (+`update_compile_order`) added before it.
- **Lock-ins of a group now share one decimation factor:** in all 10 groups `axi_control_0/dec_factor` drives
  `lockin_0..3/dec_factor`. Reason: a group's stream is clocked only by `lockin_3/output_valid`; if a lane had a different
  (or never-written, power-on 0) `dec_factor` its data was repeated/mis-decimated or the DMA stalled. Software only has
  to write `dec_factor` of lane 0 of each active group (writing the others is harmless, they are now unused).

## 3b. `patch_main_bd.tcl` – apply sections 2-3 to an EXISTING project
`lockin/main.tcl` only builds a design from scratch; an already-open `lockin.xpr` keeps its saved `main.bd`
(slices still visible). To patch it in place: open the project, then in the Tcl console
`source <repo>/firmware/patch_main_bd.tcl` (adds `avg12.vhd`, swaps slice -> `avg12_0` in the 3 ADC hierarchies,
shares `dec_factor` in all groups, validates and saves). Re-runnable (skips done work).
Tested in Vivado 2023.2 batch on a copy of the project: 4+4+2 groups patched, `validate_bd_design` OK,
connectivity re-read afterwards (no `xlslice_0` left, `avg12_0` clk/data/valid wired as intended).
`dump.vhd` needs no BD change (same ports); it is picked up from `src/` -- reset/re-run synthesis of the `dump` modules.

## 4. NOT changed: ADC tile 226 clocking (needs your decision in Vivado)
Tile 226 (`adc_226_0`, `m20`) has its own PLL/refclk (`adc2_clk`) but its stream uses `m2_axis_aclk` taken from the
`clk_wiz` fed by tile 224's `clk_adc0`; `clk_adc2` is unused. This is only safe if both refclks are the same frequency
(they should come from the same LMX). I did not touch the RFDC because the clock-source options cannot be validated
without the IP GUI (they also affect pins/XDC and may need Multi-Tile-Sync + software MTS). Options, best first:
1. RFDC tile 226: *Clock Source* = Tile 224 (props `ADC2_Clock_Source`=0, tile 224 `ADC0_Clock_Dist`) so both tiles share one clock; remove `adc2_clk`.
2. Keep as is but check on hardware that `adc_226_0` is the only affected ADC; if so this is the cause.
3. Clock `m2_axis_aclk` from `clk_adc2` + own MMCM (needs CDC for run/reset/config/counters).

## To verify in Vivado
1. Add `src/avg12.vhd` (done automatically if you `source lockin/main.tcl`); regenerate BD, synth, check timing at 122.88 MHz
   (avg12 / dump are small; `dump` is now combinational on the tready path DMA -> FIFO, check it closes).
2. Check `lockin_wrapper`/group hierarchies still validate (`validate_bd_design`); unconnected `axi_control_{1,2,3}/dec_factor` outputs are expected.
3. Check utilization: +3 `avg12` (about 3 DSP, ~600 FF).

## Software follow-ups (later)
- ADC amplitude: unchanged at DC, ~-0.4 dB at 20 MHz (boxcar droop); SNR a bit better.
- Configure/trust only lane 0's `dec_factor`; unused lanes of a partly used group still need frequency/phase only if you read them.
- `num_tlast` is still unconnected in the BD (harmless).

## Multiplier rounding bias (2026-10-20, fw version unchanged = 4)
`src/multiplier.vhd` built its rounding constant from `len_c` (16) but the output cut is at bit `len_a+len_b-len_c` (18),
so it added 2^15 instead of 2^17: a bias of about -0.37 LSB at the mixer output, i.e. about -46 counts (x128 FIR gain)
DC offset in every I and Q (seen in all 40 tones of the old data). Now `cut = len_a+len_b-len_c` is used for the
constant and the tie pattern. GHDL `test/tbs/tb_multiplier.vhd`: exact round-half-even, mean error +0.001 LSB.
Expect I/Q means near 0 (plus real ADC offset effects) in new data; same fix copied to BAWSHA `rfsoc_control/firmware/src`.
