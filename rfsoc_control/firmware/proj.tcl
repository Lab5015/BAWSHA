###########################################################################
# Project settings
###########################################################################

set origin_dir "."

if {[info exists ::origin_dir_loc]} {
    set origin_dir $::origin_dir_loc
}

set proj_name "top"


###########################################################################
# Create project
###########################################################################

create_project $proj_name ./$proj_name \
    -part xczu48dr-ffvg1517-2-e \
    -force


###########################################################################
# Project properties
###########################################################################

set obj [current_project]

set_property board_part \
    "realdigital.org:rfsoc4x2:part0:1.0" \
    $obj

set_property enable_vhdl_2008 true $obj
set_property simulator_language Mixed $obj
set_property default_lib xil_defaultlib $obj


###########################################################################
# IP repository
###########################################################################

set obj [get_filesets sources_1]

set_property ip_repo_paths \
    [file normalize "$origin_dir/ip_repo"] \
    $obj

update_ip_catalog -rebuild


###########################################################################
# Add HDL sources
###########################################################################

set src_files {}

foreach ext {v sv vhd vh} {
    foreach f [glob -nocomplain -directory "$origin_dir/src" *.$ext] {
        lappend src_files $f
    }
}

if {[llength $src_files] > 0} {
    add_files -norecurse $src_files
}


###########################################################################
# Add constraints
###########################################################################

foreach f [glob -nocomplain -directory "$origin_dir/constraints" *.xdc] {
    add_files -fileset constrs_1 $f
}


###########################################################################
# Create lockin Block Design
###########################################################################

puts "Creating lockin block design..."

source [file normalize "$origin_dir/bd/lockin.tcl"]


###########################################################################
# Create main Block Design
###########################################################################

puts "Creating main block design..."

source [file normalize "$origin_dir/bd/main.tcl"]


###########################################################################
# Compile order
###########################################################################

update_compile_order -fileset sources_1


###########################################################################
# Top module
###########################################################################

set_property top main_wrapper [get_filesets sources_1]


# ###########################################################################
# # Run synthesis and implementation
# ###########################################################################
# 
# launch_runs synth_1
# wait_on_run synth_1
# 
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# 
# 
# puts "============================================"
# puts "DONE"
# puts "Bitstream generated successfully"
# puts "============================================"
