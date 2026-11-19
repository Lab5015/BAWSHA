> Migrated from the SimBa repository (2026-11-16). Paths in this note are the old SimBa ones.
> In BAWSHA: `lockin/main.tcl` is `bd/main.tcl`, `lockin/lockin.tcl` is `bd/lockin.tcl`,
> The `patch_*.tcl` scripts were removed with firmware v5 (they patch older projects and break the v5 block
> designs). `patch_main_bd.tcl` is folded into `bd/main.tcl`, `patch_lockin_bd.tcl` is replaced by section v5 A.
> Both are still in the git history.

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

## Firmware v5: fewer DSPs per lock-in, 48 lock-ins (2026-11-17, `FW_VERSION` = 5)
Goal: the 40 lock-ins of v4 used 3763 of 4272 DSPs (94 per lock-in). The late FIR stages run at low rates but each
had its own DSPs, and stages fed with 32-bit data cost 3 DSPs per path where 22 bits fit one 27x18 multiplier.

**A. Narrower data (`bd/lockin.tcl`, `bd/chain.tcl`)**
- `fir_x2` and `fir_x5_1` output 22 bits with convergent rounding (was 32 bits). `fir_x3`, `fir_x5` and `fir_x5_2`
  take 22-bit data. `fir_x3` coefficients are halved (18 bit, round half away from zero).
- Output scale is unchanged (the FIR keeps the top bits of its full-precision result, so a 22-bit input simply
  drops 10 fewer LSBs). Simulated against v4 (`tmp/dsp_patch_sim`, not committed): same noise floor and SNR,
  gain -13 ppm, DC offset change about 0.1 count, alias rejection at LO +- 20.48 MHz -114 -> -102 dB.
  Truncating instead of rounding (the old `docs/patch_lockin_bd.tcl`) gave a -30 count DC offset.
  That patch script was removed (see the note at the top).

**B. Late stages shared per group (`src/tdm_interleave.vhd`, `src/tdm_pack.vhd`, `src/chain_wrapper.vhd`, `bd/chain.tcl`)**
- `lockin_wrapper` now ends at `fir_x5` (24-bit I/Q at 4.096 MS/s, no `dec_factor` port).
- Per group, `tdm_interleave` turns the 4 x {I, Q} into one 8-channel TDM stream for `fir_x5_1` .. `fir_compiler_x5_2`
  (FIR Compiler with `Number_Channels` 8, same coefficients and rounding as v4). `tdm_pack` rebuilds the 256-bit word
  (lock-in k I at bits 64k+31..64k, Q at 64k+63..64k+32, as before) and `decimate` (dec_factor of lane 0) follows.
  Everything after (stop_if_fifo_full, fifo, dump, DMA) is unchanged.
- `chain` outputs `overflow` (a set arrived while the previous was still being sent) and `sync_error` (tlast not on
  channel 7). Both are sticky and currently unconnected (debug only, they should never be set).
- `axi_control_k/test_reg` now shows lane k's I word of the chain output (was lockin_k output_I).

**48 lock-ins (`bd/main.tcl`, parametric rewrite)**
- 3 ADC x 4 groups x 4 lock-ins. `adc_226_0` gains `group_2` and `group_3`, counters `counter_10/11`.
- New addresses: group 10 at 0xA0320000 (controllers) / 0xA0360000 (DMA), group 11 at 0xA0370000 / 0xA03B0000.
  Old addresses are unchanged. The AXI-lite interconnect now uses all 64 masters.
- Software finds the lock-ins by name, so no change besides `FW_VERSION`.

**Tests**
- GHDL: `tb_tdm_interleave` (592 bursts, overload and reset cases, 0 errors), `tb_tdm_pack` (880 words, 160 injected
  framing errors detected, 0 errors).
- xsim `test/tbs/tb_chain.vhd` (chain BD, 19.6k input sets, 8 different channels incl. a full-scale one), compared
  bit-exact with an integer model: fir_x5_1 .. fir_x5_4 exact on all channels (3915 / 782 / 155 / 30 outputs per
  channel), shifts as predicted (20, 10, 20, 20), tlast always on channel 7. The last two stages need >9M clocks per
  20 outputs (xsim runs a few hundred clocks/s), so they were checked in a separate BD with the same FIR cells fed
  faster (only Sample_Frequency raised): fir_compiler_x5 500 and fir_compiler_x5_2 100 outputs per channel, and 100
  packed 256-bit words after tdm_pack + decimate, 0 mismatches, no wrap with a full-scale input.
- Vivado: main BD with 48 lock-ins validates. OOC synthesis DSPs: front end 32 per lock-in (iq_mult 4, x2 6, x3 16,
  x5 6, was 58), chain 18 per group (was 36 per lock-in). Total about 1752 (41%) vs 3763 for 40 lock-ins in v4.
- Full build (Vivado 2023.2, 2026-11-18): timing met (WNS +0.985 ns, WHS +0.009 ns), all nets routed, no DRC errors.
  Utilization v4 (40) -> v5 (48): DSP 3763 -> 1755, LUT 252k -> 185k, FF 511k -> 381k, BRAM 460 -> 330,
  URAM 40 -> 48. Not yet tested on hardware.

**Server: first transfer dropped (`rf_soc_server.py`, applies to v4 too)**
The FIRs only get samples while `run` is high (the DDS valid gates the mixer) and the soft reset does not clear
them. So every acquisition started with about 0.5 s of the previous one (old LO) still leaving the filters
(115 taps at 262 Hz in the last stage plus the earlier stages). After a retune this can show a line of the
previous band at the new frequency, and not on a repeat. The server now drops the first DMA transfer
(256 samples, about 1 s) after `start`. Row timing is unchanged because it comes from the hardware counter.

**Revert:** check out `bd/lockin.tcl`, `bd/main.tcl`, `src/lockin_wrapper.vhd` and `proj.tcl` from before this change,
drop `bd/chain.tcl` and the 3 new `src` files, set `FW_VERSION` back to 4.
