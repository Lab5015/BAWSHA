# Reduces the DSP usage of the lock-in filter chain (lockin.bd, hierarchy double_datapath).
#
# Why: the FIR compiler needs extra DSPs whenever the accumulation does not fit the
#   48-bit DSP48E2 accumulator (Data_Width + Coefficient_Width + ceil(log2(taps)) > 48)
#   or the coefficients are wider than the 18-bit multiplier port. Measured with
#   out-of-context synthesis (2 paths): fir_x3 34 -> 16 DSP, fir_x5 14 -> 6,
#   fir_x5_1 / fir_x5_2 6 -> 2, i.e. about 94 -> 60 DSP per lock-in (x40).
#
# What:
#  * fir_x3, fir_x5, fir_x5_1, fir_x5_2: Data_Width 22 (inputs are the TOP 22 bit of the
#    previous stage's 32-bit output; an axis_subset_converter in front of each stage
#    builds the 2 x 24-bit slots {sign, sign, bits[31:10]}).
#  * fir_x3 only: coefficients 19 -> 18 bit (halved and rounded; worst stopband
#    -98 dB -> -89 dB, DC gain unchanged).
#  Output_Width stays 32 everywhere, so the scale of every stage output is unchanged
#  (behavioural simulation of fir_x3: identical output up to input truncation).
#  The truncation noise referred to the final 262 Hz band is <= ~1.3e-3 LSB of the
#  mixer output, far below the ADC noise floor.
#  To undo one stage: delete its *_cvt, reconnect the AXI-Stream, Data_Width back to 32.
#
# Usage: open the project, then in the Tcl console
#   source <repo>/firmware/patch_lockin_bd.tcl
# then regenerate output products / re-run synthesis of the lock-in modules.
# Re-runnable (skips stages that are already narrowed).

set narrow_pairs {
  {fir_x2   fir_x3}
  {fir_x3   fir_x5}
  {fir_x5   fir_x5_1}
  {fir_x5_1 fir_x5_2}
}
set data_w 22
# per path: {sign, sign, bits[31:10]}, path 1 = tdata[63:32], path 0 = tdata[31:0]
set remap "tdata\[63\],tdata\[63\],tdata\[63:42\],tdata\[31\],tdata\[31\],tdata\[31:10\]"

open_bd_design [get_files lockin.bd]
set top [current_bd_instance .]
current_bd_instance /double_datapath

foreach pair $narrow_pairs {
  lassign $pair src dst
  if { [llength [get_bd_cells -quiet ${dst}_cvt]] } {
    puts "$dst: already narrowed, skipped"
    continue
  }
  set intf [get_bd_intf_nets -quiet -of_objects [get_bd_intf_pins $dst/S_AXIS_DATA]]
  if { $intf eq "" } { error "$dst/S_AXIS_DATA is not connected" }
  delete_bd_objs $intf

  set src_rdy [get_property CONFIG.HAS_TREADY [get_bd_intf_pins $src/M_AXIS_DATA]]
  set cvt [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 ${dst}_cvt]
  set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES 8 \
    CONFIG.M_TDATA_NUM_BYTES 6 \
    CONFIG.TDATA_REMAP $remap \
    CONFIG.S_HAS_TREADY $src_rdy \
    CONFIG.M_HAS_TREADY 1] $cvt

  set_property CONFIG.Data_Width $data_w [get_bd_cells $dst]
  connect_bd_intf_net [get_bd_intf_pins $src/M_AXIS_DATA] [get_bd_intf_pins ${dst}_cvt/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins ${dst}_cvt/M_AXIS] [get_bd_intf_pins $dst/S_AXIS_DATA]
  connect_bd_net [get_bd_pins clk]     [get_bd_pins ${dst}_cvt/aclk]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins ${dst}_cvt/aresetn]
  puts "$dst: Data_Width $data_w, fed from top 22 bit of $src"
}

# fir_x3: 18-bit coefficients (halved, rounded half away from zero)
if { [get_property CONFIG.Coefficient_Width [get_bd_cells fir_x3]] == 19 } {
  set old [split [string map {"," " "} [get_property CONFIG.CoefficientVector [get_bd_cells fir_x3]]] " "]
  set new {}
  foreach c $old {
    if { $c eq "" } continue
    set h [expr {$c / 2.0}]
    lappend new [expr {int($h >= 0 ? floor($h + 0.5) : -floor(-$h + 0.5))}]
  }
  set_property -dict [list CONFIG.Coefficient_Width 18 CONFIG.CoefficientVector [join $new ","]] [get_bd_cells fir_x3]
  puts "fir_x3: coefficients reduced to 18 bit ([llength $new] taps, sum [expr [join $new +]])"
}

current_bd_instance $top
validate_bd_design
save_bd_design
puts "patch_lockin_bd: done"
