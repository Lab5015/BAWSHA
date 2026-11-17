# Applies, in place, to the OPEN project (lockin.xpr) the Block Design changes that
# lockin/main.tcl only applies when it builds a design from scratch:
#   1. in adc_224_0 / adc_224_1 / adc_226_0: replace xlslice_0 (first sample only)
#      with the avg12 module (average of the 12 RFDC samples per clock)
#   2. in every group: lockin_1..3 take dec_factor from axi_control_0
# Usage (Vivado Tcl console, project open):  source <path>/firmware/patch_main_bd.tcl
# Safe to re-run: already patched cells are skipped.

set fw_dir [file normalize [file join [file dirname [info script]]]]

# --- sources -------------------------------------------------------------
foreach f {avg12.vhd} {
  if { [llength [get_files -quiet $f]] == 0 } {
    add_files -norecurse [file join $fw_dir src $f]
  }
}
update_compile_order -fileset sources_1

open_bd_design [get_files main.bd]
set top [current_bd_instance .]

# --- 1. avg12 in the ADC hierarchies --------------------------------------
foreach adc {adc_224_0 adc_224_1 adc_226_0} {
  current_bd_instance $top
  if { [llength [get_bd_cells -quiet /$adc/avg12_0]] } {
    puts "$adc: avg12_0 already present, skipped"
    continue
  }
  current_bd_instance /$adc

  # nets inside the hierarchy: slice output -> groups, and raw valid -> groups
  set dnet [get_bd_nets -of_objects [get_bd_pins xlslice_0/Dout]]
  set data_loads {}
  foreach p [get_bd_pins -of_objects $dnet -filter {DIR == I}] {
    if { [string match "*/group_*" $p] } { lappend data_loads $p }
  }
  set gname [lindex [split [string trimleft [lindex $data_loads 0] /] /] 1]
  set vnet [get_bd_nets -of_objects [get_bd_pins $gname/adc_data_valid]]
  set valid_loads {}
  foreach p [get_bd_pins -of_objects $vnet -filter {DIR == I}] {
    if { [string match "*/group_*" $p] } { lappend valid_loads $p }
  }
  puts "$adc: [llength $data_loads] data loads, [llength $valid_loads] valid loads"

  foreach p $data_loads  { disconnect_bd_net $dnet $p }
  foreach p $valid_loads { disconnect_bd_net $vnet $p }
  delete_bd_objs [get_bd_cells xlslice_0]
  create_bd_cell -type module -reference avg12 avg12_0

  connect_bd_net [get_bd_pins adc_data]       [get_bd_pins avg12_0/adc_data]
  connect_bd_net [get_bd_pins clk]            [get_bd_pins avg12_0/clk]
  connect_bd_net [get_bd_pins adc_data_valid] [get_bd_pins avg12_0/adc_data_valid]
  foreach p $valid_loads { connect_bd_net [get_bd_pins avg12_0/data_valid_out] $p }
  foreach p $data_loads  { connect_bd_net [get_bd_pins avg12_0/data_out] $p }
}

# --- 2. shared dec_factor inside each group --------------------------------
foreach adc {adc_224_0 adc_224_1 adc_226_0} {
  current_bd_instance /$adc
  foreach g [get_bd_cells -quiet group_*] {
    set gn [get_property NAME $g]
    current_bd_instance /$adc/$gn
    foreach k {1 2 3} {
      set pin [get_bd_pins lockin_$k/dec_factor]
      set net [get_bd_nets -quiet -of_objects $pin]
      if { $net ne "" } { disconnect_bd_net $net $pin }
      connect_bd_net [get_bd_pins axi_control_0/dec_factor] $pin
    }
    current_bd_instance /$adc
  }
}

current_bd_instance $top
validate_bd_design
save_bd_design
puts "patch_main_bd: done"
