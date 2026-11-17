###########################################################################
# Resume an interrupted implementation from the last saved checkpoint.
#
#   vivado -mode batch -source resume_impl.tcl
#
# Use it when build.tcl was stopped or crashed after opt_design: it skips
# link_design and opt_design (about 2 h on a 16 GB machine). It continues
# from the most advanced of the routed / physopt / placed / opt checkpoints
# in top/top.runs/impl_1 and saves a checkpoint after every step, so it can
# itself be re-run.
# It works outside the project: the Vivado GUI keeps showing impl_1 as not
# finished, the bitstream is the same.
# Environment (optional):
#   BUILD_THREADS  default 2 (see build.tcl)
###########################################################################

set threads [expr {[info exists ::env(BUILD_THREADS)] ? $::env(BUILD_THREADS) : 2}]
set dir     [file normalize top/top.runs/impl_1]
set top     main_wrapper

if {[info exists ::env(RFSOC4X2_BOARD_FILES)]} {
    set board_repo $::env(RFSOC4X2_BOARD_FILES)
} else {
    set board_repo [file join $::env(HOME) .Vivado RFSoC4x2-BSP board_files]
}
if {[file isdirectory $board_repo]} {
    set_param board.repoPaths [list $board_repo]
}
set_param general.maxThreads $threads

# step that produced each checkpoint, most advanced first
set stages {routed physopt placed opt}
set start ""
foreach s $stages {
    if {[file exists $dir/${top}_$s.dcp]} {
        set start $s
        break
    }
}
if {$start eq ""} {
    error "No checkpoint in $dir, run build.tcl instead"
}
puts "BUILD RESUME: from ${top}_$start.dcp"
open_checkpoint $dir/${top}_$start.dcp

if {$start eq "opt"} {
    place_design
    write_checkpoint -force $dir/${top}_placed.dcp
    set start placed
}
if {$start eq "placed"} {
    phys_opt_design
    write_checkpoint -force $dir/${top}_physopt.dcp
    set start physopt
}
if {$start eq "physopt"} {
    route_design
    write_checkpoint -force $dir/${top}_routed.dcp
}

report_route_status    -file $dir/${top}_route_status.rpt
report_timing_summary  -max_paths 10 -file $dir/${top}_timing_summary_routed.rpt
report_utilization     -file $dir/${top}_utilization_placed.rpt
report_drc             -file $dir/${top}_drc_routed.rpt

set wns [get_property SLACK [get_timing_paths -setup]]
set whs [get_property SLACK [get_timing_paths -hold]]
puts "BUILD TIMING: WNS $wns ns, WHS $whs ns"
if {$wns < 0 || $whs < 0} {
    error "Build failed: timing not met, no bitstream written"
}

write_bitstream -force $dir/$top.bit
puts "BUILD STATUS: write_bitstream Complete!"
puts "BUILD OUTPUT: $dir/$top.bit"
puts "BUILD OUTPUT: [lindex [glob -nocomplain top/top.gen/sources_1/bd/main/hw_handoff/main.hwh] 0]"
puts "Copy them to firmware_imgs/lockin.bit and firmware_imgs/lockin.hwh after checking the timing."
