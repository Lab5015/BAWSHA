###########################################################################
# Build the bitstream: synthesis, implementation, write_bitstream.
#
#   vivado -mode batch -source build.tcl
#
# Creates the project with proj.tcl if ./top does not exist yet.
# Can be re-run after a failure: finished runs are kept.
# Environment (optional):
#   BUILD_JOBS     parallel runs, default 2 (each needs several GB of RAM)
#   BUILD_THREADS  threads per run, default 2. With 8 threads route_design
#                  crashed once in Vivado 2023.2 (segfault in "Resolve XTalk").
# Output: top/top.runs/impl_1/main_wrapper.bit and the main.hwh printed at the end.
###########################################################################

set jobs    [expr {[info exists ::env(BUILD_JOBS)]    ? $::env(BUILD_JOBS)    : 2}]
set threads [expr {[info exists ::env(BUILD_THREADS)] ? $::env(BUILD_THREADS) : 2}]

if {[file exists top/top.xpr]} {
    open_project top/top.xpr
} else {
    source proj.tcl
}

set_param general.maxThreads $threads

# Projects created before proj.tcl set this
set_property file_type {VHDL 2008} [get_files {*/src/multiplier.vhd */src/interpolator.vhd}]

# Keep finished runs (IP synthesis takes hours), redo only failed or stale ones
foreach run [get_runs] {
    if {[get_property PROGRESS $run] ne "100%" || [get_property NEEDS_REFRESH $run]} {
        puts "BUILD RESET: $run"
        reset_run $run
    }
}

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1

set status [get_property STATUS [get_runs impl_1]]
puts "BUILD STATUS: $status"
if {![string match "*write_bitstream Complete*" $status]} {
    error "Build failed: $status"
}

open_run impl_1
puts "BUILD TIMING: WNS [get_property SLACK [get_timing_paths -setup]] ns, WHS [get_property SLACK [get_timing_paths -hold]] ns"
puts "BUILD OUTPUT: [file normalize top/top.runs/impl_1/main_wrapper.bit]"
puts "BUILD OUTPUT: [lindex [glob -nocomplain top/top.gen/sources_1/bd/main/hw_handoff/main.hwh] 0]"
puts "Copy them to firmware_imgs/lockin.bit and firmware_imgs/lockin.hwh after checking the timing."
