
################################################################
# This is a generated script based on design: main
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source main_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump, lockin_wrapper, lockin_wrapper, lockin_wrapper, lockin_wrapper, sing_counter_mod, dump

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu48dr-ffvg1517-2-e
   set_property BOARD_PART realdigital.org:rfsoc4x2:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name main

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:zynq_ultra_ps_e:3.5\
xilinx.com:ip:usp_rf_data_converter:2.6\
xilinx.com:ip:proc_sys_reset:5.0\
user.org:user:global_axi_control:1.2\
xilinx.com:ip:clk_wiz:6.0\
user.org:user:external_start_sync:1.0\
xilinx.com:ip:smartconnect:1.0\
user.org:user:counters:1.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
user.org:user:controller_lockin:1.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:axis_subset_converter:1.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:axi_dma:7.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
lockin_wrapper\
sing_counter_mod\
dump\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: group_1
proc create_hier_cell_group_1_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_1_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_1/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_1/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_1/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_1/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_0
proc create_hier_cell_group_0_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_0_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_0/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_0/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_0/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_226_0/group_0/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_3
proc create_hier_cell_group_3_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_3_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_3/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_3/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_3/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_3/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_2
proc create_hier_cell_group_2_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_2_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_2/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_2/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_2/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_2/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_1
proc create_hier_cell_group_1_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_1_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_1/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_1/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_1/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_1/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_0
proc create_hier_cell_group_0_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_0_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_0/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_0/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_0/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_1/group_0/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_3
proc create_hier_cell_group_3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_3/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_3/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_3/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_3/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_2
proc create_hier_cell_group_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_2/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_2/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_2/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_2/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_1
proc create_hier_cell_group_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_1/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_1/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_1/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_1/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_1/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_3/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_1/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_3/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_1/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_3/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_1/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_3/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_1/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_3/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_1/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_3/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: group_0
proc create_hier_cell_group_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_group_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I config_port
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir I -from 15 -to 0 adc_data

  # Create instance: axi_control_0, and set properties
  set axi_control_0 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_0 ]

  # Create instance: lockin_0, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_0
  if { [catch {set lockin_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_0/lockin_0/reset]

  # Create instance: concat_0, and set properties
  set concat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_0


  # Create instance: lockin_1, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_1
  if { [catch {set lockin_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_0/lockin_1/reset]

  # Create instance: axi_control_1, and set properties
  set axi_control_1 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_1 ]

  # Create instance: concat_1, and set properties
  set concat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_1 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_1


  # Create instance: lockin_2, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_2
  if { [catch {set lockin_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_0/lockin_2/reset]

  # Create instance: axi_control_2, and set properties
  set axi_control_2 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_2 ]

  # Create instance: concat_2, and set properties
  set concat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_2


  # Create instance: lockin_3, and set properties
  set block_name lockin_wrapper
  set block_cell_name lockin_3
  if { [catch {set lockin_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $lockin_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /adc_224_0/group_0/lockin_3/reset]

  # Create instance: axi_control_3, and set properties
  set axi_control_3 [ create_bd_cell -type ip -vlnv user.org:user:controller_lockin:1.0 axi_control_3 ]

  # Create instance: concat_3, and set properties
  set concat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_3 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {32} \
    CONFIG.IN1_WIDTH {32} \
  ] $concat_3


  # Create instance: concat, and set properties
  set concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {64} \
    CONFIG.IN1_WIDTH {64} \
    CONFIG.IN2_WIDTH {64} \
    CONFIG.IN3_WIDTH {64} \
    CONFIG.NUM_PORTS {4} \
  ] $concat


  # Create instance: stop_if_fifo_full, and set properties
  set stop_if_fifo_full [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 stop_if_fifo_full ]
  set_property -dict [list \
    CONFIG.M_HAS_TLAST {0} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {0} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $stop_if_fifo_full


  # Create instance: count_dropped, and set properties
  set block_name sing_counter_mod
  set block_cell_name count_dropped
  if { [catch {set count_dropped [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $count_dropped eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: fifo, and set properties
  set fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 fifo ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.HAS_PROG_FULL {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.IS_ACLK_ASYNC {0} \
    CONFIG.TDATA_NUM_BYTES {32} \
  ] $fifo


  # Create instance: dump, and set properties
  set block_name dump
  set block_cell_name dump
  if { [catch {set dump [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $dump eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axis_subset_converter, and set properties
  set axis_subset_converter [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter ]
  set_property -dict [list \
    CONFIG.DEFAULT_TLAST {256} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.M_HAS_TREADY {1} \
    CONFIG.M_TDATA_NUM_BYTES {32} \
    CONFIG.S_HAS_TREADY {1} \
    CONFIG.S_TDATA_NUM_BYTES {32} \
  ] $axis_subset_converter


  # Create instance: dma, and set properties
  set dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dma ]
  set_property -dict [list \
    CONFIG.c_addr_width {32} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_s2mm_burst_size {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {256} \
    CONFIG.c_sg_length_width {26} \
  ] $dma


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins dma/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE]
  connect_bd_intf_net -intf_net S00_AXI1_1 [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_control_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI2_1 [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins axi_control_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins axi_control_2/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins axi_control_1/S00_AXI]
  connect_bd_intf_net -intf_net axis_subset_converter_M_AXIS [get_bd_intf_pins axis_subset_converter/M_AXIS] [get_bd_intf_pins dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net count_dropped_m_axis [get_bd_intf_pins count_dropped/m_axis] [get_bd_intf_pins fifo/S_AXIS]
  connect_bd_intf_net -intf_net dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dump_m_axi [get_bd_intf_pins dump/m_axi] [get_bd_intf_pins axis_subset_converter/S_AXIS]
  connect_bd_intf_net -intf_net fifo_M_AXIS [get_bd_intf_pins fifo/M_AXIS] [get_bd_intf_pins dump/s_axi]
  connect_bd_intf_net -intf_net stop_if_fifo_full_M_AXIS [get_bd_intf_pins stop_if_fifo_full/M_AXIS] [get_bd_intf_pins count_dropped/s_axis]

  # Create port connections
  connect_bd_net -net axi_control_dec_factor [get_bd_pins axi_control_0/dec_factor] [get_bd_pins lockin_0/dec_factor]
  connect_bd_net -net axi_control_dec_factor_1 [get_bd_pins axi_control_1/dec_factor] [get_bd_pins lockin_1/dec_factor]
  connect_bd_net -net axi_control_dec_factor_2 [get_bd_pins axi_control_2/dec_factor] [get_bd_pins lockin_2/dec_factor]
  connect_bd_net -net axi_control_dec_factor_3 [get_bd_pins axi_control_3/dec_factor] [get_bd_pins lockin_3/dec_factor]
  connect_bd_net -net axi_control_frequency [get_bd_pins axi_control_0/frequency] [get_bd_pins lockin_0/init_freq]
  connect_bd_net -net axi_control_num_tlast [get_bd_pins axi_control_0/num_tlast]
  connect_bd_net -net axi_control_num_tlast_1 [get_bd_pins axi_control_1/num_tlast]
  connect_bd_net -net axi_control_num_tlast_2 [get_bd_pins axi_control_2/num_tlast]
  connect_bd_net -net axi_control_num_tlast_3 [get_bd_pins axi_control_3/num_tlast]
  connect_bd_net -net axi_control_phase [get_bd_pins axi_control_0/phase] [get_bd_pins lockin_0/init_phase]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins stop_if_fifo_full/aclk] [get_bd_pins fifo/s_axis_aclk] [get_bd_pins axis_subset_converter/aclk] [get_bd_pins dma/m_axi_s2mm_aclk] [get_bd_pins dump/clk] [get_bd_pins lockin_0/clk] [get_bd_pins lockin_3/clk] [get_bd_pins lockin_2/clk] [get_bd_pins lockin_1/clk] [get_bd_pins count_dropped/clk]
  connect_bd_net -net concat_0_dout [get_bd_pins concat_0/dout] [get_bd_pins concat/In0]
  connect_bd_net -net concat_1_dout [get_bd_pins concat_1/dout] [get_bd_pins concat/In1]
  connect_bd_net -net concat_2_dout [get_bd_pins concat_2/dout] [get_bd_pins concat/In2]
  connect_bd_net -net concat_3_dout [get_bd_pins concat_3/dout] [get_bd_pins concat/In3]
  connect_bd_net -net concat_dout [get_bd_pins concat/dout] [get_bd_pins stop_if_fifo_full/s_axis_tdata]
  connect_bd_net -net controller_lockin_0_frequency [get_bd_pins axi_control_1/frequency] [get_bd_pins lockin_1/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_1 [get_bd_pins axi_control_2/frequency] [get_bd_pins lockin_2/init_freq]
  connect_bd_net -net controller_lockin_0_frequency_2 [get_bd_pins axi_control_3/frequency] [get_bd_pins lockin_3/init_freq]
  connect_bd_net -net controller_lockin_0_phase [get_bd_pins axi_control_1/phase] [get_bd_pins lockin_1/init_phase]
  connect_bd_net -net controller_lockin_0_phase_1 [get_bd_pins axi_control_2/phase] [get_bd_pins lockin_2/init_phase]
  connect_bd_net -net controller_lockin_0_phase_2 [get_bd_pins axi_control_3/phase] [get_bd_pins lockin_3/init_phase]
  connect_bd_net -net count_dropped_counter_port [get_bd_pins count_dropped/counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins config_port] [get_bd_pins lockin_0/config_port] [get_bd_pins lockin_3/config_port] [get_bd_pins lockin_2/config_port] [get_bd_pins lockin_1/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins reset] [get_bd_pins lockin_0/reset] [get_bd_pins lockin_3/reset] [get_bd_pins lockin_2/reset] [get_bd_pins lockin_1/reset] [get_bd_pins count_dropped/rst]
  connect_bd_net -net global_axi_control_0_run [get_bd_pins led_run] [get_bd_pins dump/run] [get_bd_pins lockin_0/run] [get_bd_pins lockin_3/run] [get_bd_pins lockin_2/run] [get_bd_pins lockin_1/run] [get_bd_pins count_dropped/run]
  connect_bd_net -net lockin_0_output_q [get_bd_pins lockin_0/output_Q] [get_bd_pins concat_0/In1]
  connect_bd_net -net lockin_output_Q [get_bd_pins lockin_1/output_Q] [get_bd_pins concat_1/In1]
  connect_bd_net -net lockin_output_i [get_bd_pins lockin_0/output_I] [get_bd_pins concat_0/In0] [get_bd_pins axi_control_0/test_reg]
  connect_bd_net -net lockin_output_q_1 [get_bd_pins lockin_2/output_Q] [get_bd_pins concat_2/In1]
  connect_bd_net -net lockin_output_q_2 [get_bd_pins lockin_3/output_Q] [get_bd_pins concat_3/In1]
  connect_bd_net -net lockin_output_valid3 [get_bd_pins lockin_3/output_valid] [get_bd_pins stop_if_fifo_full/s_axis_tvalid]
  connect_bd_net -net lockin_wrapper_0_output_i [get_bd_pins lockin_1/output_I] [get_bd_pins concat_1/In0] [get_bd_pins axi_control_1/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_1 [get_bd_pins lockin_2/output_I] [get_bd_pins concat_2/In0] [get_bd_pins axi_control_2/test_reg]
  connect_bd_net -net lockin_wrapper_0_output_i_2 [get_bd_pins lockin_3/output_I] [get_bd_pins concat_3/In0] [get_bd_pins axi_control_3/test_reg]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins dma/axi_resetn] [get_bd_pins axi_control_0/s00_axi_aresetn] [get_bd_pins axi_control_3/s00_axi_aresetn] [get_bd_pins axi_control_2/s00_axi_aresetn] [get_bd_pins axi_control_1/s00_axi_aresetn]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins stop_if_fifo_full/aresetn] [get_bd_pins fifo/s_axis_aresetn] [get_bd_pins axis_subset_converter/aresetn] [get_bd_pins lockin_0/aresetn] [get_bd_pins lockin_3/aresetn] [get_bd_pins lockin_2/aresetn] [get_bd_pins lockin_1/aresetn]
  connect_bd_net -net stop_if_fifo_full_transfer_dropped [get_bd_pins stop_if_fifo_full/transfer_dropped] [get_bd_pins count_dropped/dropped]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins adc_data] [get_bd_pins lockin_0/adc_data] [get_bd_pins lockin_3/adc_data] [get_bd_pins lockin_2/adc_data] [get_bd_pins lockin_1/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins lockin_0/adc_data_valid] [get_bd_pins lockin_3/adc_data_valid] [get_bd_pins lockin_2/adc_data_valid] [get_bd_pins lockin_1/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins dma/s_axi_lite_aclk] [get_bd_pins axi_control_0/s00_axi_aclk] [get_bd_pins axi_control_3/s00_axi_aclk] [get_bd_pins axi_control_2/s00_axi_aclk] [get_bd_pins axi_control_1/s00_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_226_0
proc create_hier_cell_adc_226_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_226_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE1


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 191 -to 0 adc_data
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst led_reset
  create_bd_pin -dir I led_config
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port1

  # Create instance: group_0
  create_hier_cell_group_0_2 $hier_obj group_0

  # Create instance: group_1
  create_hier_cell_group_1_2 $hier_obj group_1

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_WIDTH {192} \
    CONFIG.DOUT_WIDTH {16} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins group_1/S00_AXI1] [get_bd_intf_pins S00_AXI4]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins group_1/S00_AXI] [get_bd_intf_pins S00_AXI5]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins group_1/S00_AXI3] [get_bd_intf_pins S00_AXI6]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins group_1/S00_AXI2] [get_bd_intf_pins S00_AXI7]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins group_1/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM1]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins group_1/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE1]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins group_0/S00_AXI3]
  connect_bd_intf_net -intf_net lockin_instance_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins group_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M02_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins group_0/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M03_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins group_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M04_AXI [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins group_0/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M05_AXI [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins group_0/S00_AXI2]

  # Create port connections
  connect_bd_net -net adc_data_1 [get_bd_pins adc_data] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net adc_data_3 [get_bd_pins xlslice_0/Dout] [get_bd_pins group_1/adc_data] [get_bd_pins group_0/adc_data]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins group_1/clk] [get_bd_pins group_0/clk]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins led_config] [get_bd_pins group_1/config_port] [get_bd_pins group_0/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins led_reset] [get_bd_pins group_1/reset] [get_bd_pins group_0/reset]
  connect_bd_net -net group_1_valid_counter_port [get_bd_pins group_1/valid_counter_port] [get_bd_pins valid_counter_port1]
  connect_bd_net -net lockin_instance_0_valid_counter_port [get_bd_pins group_0/valid_counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins group_1/axi_resetn] [get_bd_pins group_0/axi_resetn]
  connect_bd_net -net run [get_bd_pins led_run] [get_bd_pins group_1/led_run] [get_bd_pins group_0/led_run]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins group_1/s_axis_aresetn] [get_bd_pins group_0/s_axis_aresetn]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins group_1/adc_data_valid] [get_bd_pins group_0/adc_data_valid]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins group_1/s_axi_lite_aclk] [get_bd_pins group_0/s_axi_lite_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_224_1
proc create_hier_cell_adc_224_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_224_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI11

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI15

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE3


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 191 -to 0 adc_data
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst led_reset
  create_bd_pin -dir I led_config
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port1
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port2
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port3

  # Create instance: group_0
  create_hier_cell_group_0_1 $hier_obj group_0

  # Create instance: group_1
  create_hier_cell_group_1_1 $hier_obj group_1

  # Create instance: group_2
  create_hier_cell_group_2_1 $hier_obj group_2

  # Create instance: group_3
  create_hier_cell_group_3_1 $hier_obj group_3

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_WIDTH {192} \
    CONFIG.DOUT_WIDTH {16} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins group_1/S00_AXI1] [get_bd_intf_pins S00_AXI4]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins group_1/S00_AXI] [get_bd_intf_pins S00_AXI5]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins group_1/S00_AXI3] [get_bd_intf_pins S00_AXI6]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins group_1/S00_AXI2] [get_bd_intf_pins S00_AXI7]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins group_1/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM1]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins group_1/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE1]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins group_2/S00_AXI1] [get_bd_intf_pins S00_AXI8]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins group_2/S00_AXI] [get_bd_intf_pins S00_AXI9]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins group_2/S00_AXI3] [get_bd_intf_pins S00_AXI10]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins group_2/S00_AXI2] [get_bd_intf_pins S00_AXI11]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins group_2/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM2]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins group_2/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE2]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins group_3/S00_AXI1] [get_bd_intf_pins S00_AXI12]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins group_3/S00_AXI] [get_bd_intf_pins S00_AXI13]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins group_3/S00_AXI3] [get_bd_intf_pins S00_AXI14]
  connect_bd_intf_net -intf_net Conn16 [get_bd_intf_pins group_3/S00_AXI2] [get_bd_intf_pins S00_AXI15]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins group_3/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM3]
  connect_bd_intf_net -intf_net Conn18 [get_bd_intf_pins group_3/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE3]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins group_0/S00_AXI3]
  connect_bd_intf_net -intf_net lockin_instance_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins group_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M02_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins group_0/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M03_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins group_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M04_AXI [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins group_0/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M05_AXI [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins group_0/S00_AXI2]

  # Create port connections
  connect_bd_net -net adc_data_1 [get_bd_pins adc_data] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins group_1/clk] [get_bd_pins group_2/clk] [get_bd_pins group_3/clk] [get_bd_pins group_0/clk]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins led_config] [get_bd_pins group_2/config_port] [get_bd_pins group_3/config_port] [get_bd_pins group_1/config_port] [get_bd_pins group_0/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins led_reset] [get_bd_pins group_2/reset] [get_bd_pins group_3/reset] [get_bd_pins group_1/reset] [get_bd_pins group_0/reset]
  connect_bd_net -net group_1_valid_counter_port [get_bd_pins group_1/valid_counter_port] [get_bd_pins valid_counter_port1]
  connect_bd_net -net group_2_valid_counter_port [get_bd_pins group_2/valid_counter_port] [get_bd_pins valid_counter_port2]
  connect_bd_net -net group_3_valid_counter_port [get_bd_pins group_3/valid_counter_port] [get_bd_pins valid_counter_port3]
  connect_bd_net -net lockin_instance_0_valid_counter_port [get_bd_pins group_0/valid_counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins group_2/axi_resetn] [get_bd_pins group_3/axi_resetn] [get_bd_pins group_1/axi_resetn] [get_bd_pins group_0/axi_resetn]
  connect_bd_net -net run [get_bd_pins led_run] [get_bd_pins group_2/led_run] [get_bd_pins group_3/led_run] [get_bd_pins group_1/led_run] [get_bd_pins group_0/led_run]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins group_2/s_axis_aresetn] [get_bd_pins group_3/s_axis_aresetn] [get_bd_pins group_1/s_axis_aresetn] [get_bd_pins group_0/s_axis_aresetn]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins group_2/adc_data_valid] [get_bd_pins group_3/adc_data_valid] [get_bd_pins group_1/adc_data_valid] [get_bd_pins group_0/adc_data_valid]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins xlslice_0/Dout] [get_bd_pins group_3/adc_data] [get_bd_pins group_2/adc_data] [get_bd_pins group_0/adc_data] [get_bd_pins group_1/adc_data]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins group_2/s_axi_lite_aclk] [get_bd_pins group_3/s_axi_lite_aclk] [get_bd_pins group_1/s_axi_lite_aclk] [get_bd_pins group_0/s_axi_lite_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: adc_224_0
proc create_hier_cell_adc_224_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_adc_224_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI5

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI6

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI7

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI8

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI9

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI10

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI11

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI12

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI13

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI14

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI15

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE3


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 191 -to 0 adc_data
  create_bd_pin -dir I adc_data_valid
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type rst led_reset
  create_bd_pin -dir I led_config
  create_bd_pin -dir I led_run
  create_bd_pin -dir I -type rst s_axis_aresetn
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port1
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port2
  create_bd_pin -dir O -from 63 -to 0 valid_counter_port3

  # Create instance: group_0
  create_hier_cell_group_0 $hier_obj group_0

  # Create instance: group_1
  create_hier_cell_group_1 $hier_obj group_1

  # Create instance: group_2
  create_hier_cell_group_2 $hier_obj group_2

  # Create instance: group_3
  create_hier_cell_group_3 $hier_obj group_3

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_WIDTH {192} \
    CONFIG.DOUT_WIDTH {16} \
  ] $xlslice_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins group_1/S00_AXI1] [get_bd_intf_pins S00_AXI4]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins group_1/S00_AXI] [get_bd_intf_pins S00_AXI5]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins group_1/S00_AXI3] [get_bd_intf_pins S00_AXI6]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins group_1/S00_AXI2] [get_bd_intf_pins S00_AXI7]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins group_1/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM1]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins group_1/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE1]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins group_2/S00_AXI1] [get_bd_intf_pins S00_AXI8]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins group_2/S00_AXI] [get_bd_intf_pins S00_AXI9]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins group_2/S00_AXI3] [get_bd_intf_pins S00_AXI10]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins group_2/S00_AXI2] [get_bd_intf_pins S00_AXI11]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins group_2/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM2]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins group_2/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE2]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins group_3/S00_AXI1] [get_bd_intf_pins S00_AXI12]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins group_3/S00_AXI] [get_bd_intf_pins S00_AXI13]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins group_3/S00_AXI3] [get_bd_intf_pins S00_AXI14]
  connect_bd_intf_net -intf_net Conn16 [get_bd_intf_pins group_3/S00_AXI2] [get_bd_intf_pins S00_AXI15]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins group_3/M_AXI_S2MM] [get_bd_intf_pins M_AXI_S2MM3]
  connect_bd_intf_net -intf_net Conn18 [get_bd_intf_pins group_3/S_AXI_LITE] [get_bd_intf_pins S_AXI_LITE3]
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins S00_AXI3] [get_bd_intf_pins group_0/S00_AXI3]
  connect_bd_intf_net -intf_net lockin_instance_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins group_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M02_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins group_0/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M03_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins group_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M04_AXI [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins group_0/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M05_AXI [get_bd_intf_pins S00_AXI2] [get_bd_intf_pins group_0/S00_AXI2]

  # Create port connections
  connect_bd_net -net adc_data_1 [get_bd_pins adc_data] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk] [get_bd_pins group_1/clk] [get_bd_pins group_2/clk] [get_bd_pins group_3/clk] [get_bd_pins group_0/clk]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins led_config] [get_bd_pins group_2/config_port] [get_bd_pins group_3/config_port] [get_bd_pins group_1/config_port] [get_bd_pins group_0/config_port]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins led_reset] [get_bd_pins group_2/reset] [get_bd_pins group_3/reset] [get_bd_pins group_1/reset] [get_bd_pins group_0/reset]
  connect_bd_net -net group_1_valid_counter_port [get_bd_pins group_1/valid_counter_port] [get_bd_pins valid_counter_port1]
  connect_bd_net -net group_2_valid_counter_port [get_bd_pins group_2/valid_counter_port] [get_bd_pins valid_counter_port2]
  connect_bd_net -net group_3_valid_counter_port [get_bd_pins group_3/valid_counter_port] [get_bd_pins valid_counter_port3]
  connect_bd_net -net lockin_instance_0_valid_counter_port [get_bd_pins group_0/valid_counter_port] [get_bd_pins valid_counter_port]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins group_2/axi_resetn] [get_bd_pins group_3/axi_resetn] [get_bd_pins group_1/axi_resetn] [get_bd_pins group_0/axi_resetn]
  connect_bd_net -net run [get_bd_pins led_run] [get_bd_pins group_2/led_run] [get_bd_pins group_3/led_run] [get_bd_pins group_1/led_run] [get_bd_pins group_0/led_run]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins s_axis_aresetn] [get_bd_pins group_2/s_axis_aresetn] [get_bd_pins group_3/s_axis_aresetn] [get_bd_pins group_1/s_axis_aresetn] [get_bd_pins group_0/s_axis_aresetn]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins adc_data_valid] [get_bd_pins group_2/adc_data_valid] [get_bd_pins group_3/adc_data_valid] [get_bd_pins group_1/adc_data_valid] [get_bd_pins group_0/adc_data_valid]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins xlslice_0/Dout] [get_bd_pins group_1/adc_data] [get_bd_pins group_0/adc_data] [get_bd_pins group_2/adc_data] [get_bd_pins group_3/adc_data]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins s_axi_lite_aclk] [get_bd_pins group_2/s_axi_lite_aclk] [get_bd_pins group_3/s_axi_lite_aclk] [get_bd_pins group_1/s_axi_lite_aclk] [get_bd_pins group_0/s_axi_lite_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set sysref_in [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_usp_rf_data_converter:diff_pins_rtl:1.0 sysref_in ]

  set adc0_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc0_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {2000000000.0} \
   ] $adc0_clk

  set vin0_01 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin0_01 ]

  set vin0_23 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin0_23 ]

  set adc2_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 adc2_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {491520000.0} \
   ] $adc2_clk

  set vin2_01 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 vin2_01 ]


  # Create ports
  set led_r [ create_bd_port -dir O led_r ]
  set led_g [ create_bd_port -dir O led_g ]
  set led_b [ create_bd_port -dir O led_b ]
  set led_run [ create_bd_port -dir O led_run ]
  set led_config [ create_bd_port -dir O led_config ]
  set led_reset [ create_bd_port -dir O -type rst led_reset ]
  set from_pps [ create_bd_port -dir I from_pps ]

  # Create instance: zynq_ultra_ps, and set properties
  set zynq_ultra_ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps ]
  set_property -dict [list \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS33} \
    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
    CONFIG.PSU_MIO_12_POLARITY {Default} \
    CONFIG.PSU_MIO_17_POLARITY {Default} \
    CONFIG.PSU_MIO_20_POLARITY {Default} \
    CONFIG.PSU_MIO_23_POLARITY {Default} \
    CONFIG.PSU_MIO_26_POLARITY {Default} \
    CONFIG.PSU_MIO_27_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_27_POLARITY {Default} \
    CONFIG.PSU_MIO_28_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_28_POLARITY {Default} \
    CONFIG.PSU_MIO_28_SLEW {fast} \
    CONFIG.PSU_MIO_29_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_29_POLARITY {Default} \
    CONFIG.PSU_MIO_30_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_30_POLARITY {Default} \
    CONFIG.PSU_MIO_30_SLEW {fast} \
    CONFIG.PSU_MIO_31_POLARITY {Default} \
    CONFIG.PSU_MIO_34_POLARITY {Default} \
    CONFIG.PSU_MIO_35_POLARITY {Default} \
    CONFIG.PSU_MIO_76_POLARITY {Default} \
    CONFIG.PSU_MIO_77_POLARITY {Default} \
    CONFIG.PSU_MIO_7_POLARITY {Default} \
    CONFIG.PSU_MIO_8_POLARITY {Default} \
    CONFIG.PSU_MIO_TREE_PERIPHERALS {SPI 0#SPI 0#SPI 0#SPI 0#SPI 0#SPI 0#SPI 1#GPIO0 MIO#GPIO0 MIO#SPI 1#SPI 1#SPI 1#GPIO0 MIO#SD 0#SD 0#SD 0#SD 0#GPIO0 MIO#I2C 0#I2C 0#GPIO0 MIO#SD 0#SD 0#GPIO0 MIO#SD\
0#SD 0#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#GPIO1 MIO#UART 1#UART 1#GPIO1 MIO#GPIO1 MIO#I2C 1#I2C 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#MDIO 1#MDIO 1#USB\
0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#USB 1#GPIO2 MIO#GPIO2 MIO} \
    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#n_ss_out[2]#n_ss_out[1]#n_ss_out[0]#miso#mosi#sclk_out#gpio0[7]#gpio0[8]#n_ss_out[0]#miso#mosi#gpio0[12]#sdio0_data_out[0]#sdio0_data_out[1]#sdio0_data_out[2]#sdio0_data_out[3]#gpio0[17]#scl_out#sda_out#gpio0[20]#sdio0_cmd_out#sdio0_clk_out#gpio0[23]#sdio0_cd_n#sdio0_wp#gpio1[26]#gpio1[27]#gpio1[28]#gpio1[29]#gpio1[30]#gpio1[31]#txd#rxd#gpio1[34]#gpio1[35]#scl_out#sda_out#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem1_mdc#gem1_mdio_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#gpio2[76]#gpio2[77]}\
\
    CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {4} \
    CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
    CONFIG.PSU__ACT_DDR_FREQ_MHZ {1199.999756} \
    CONFIG.PSU__AFI0_COHERENCY {0} \
    CONFIG.PSU__AFI1_COHERENCY {0} \
    CONFIG.PSU__CAN1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1199.999756} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {599.999878} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {599.999878} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__ACT_FREQMHZ {24.999996} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__ACT_FREQMHZ {26.249996} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__ACT_FREQMHZ {299.999939} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {599.999878} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {399.999908} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {533.33} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {524.999939} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {533.333} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999992} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.999908} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1499.999756} \
    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__ACT_FREQMHZ {124.999977} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {262.499969} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {267} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {524.999939} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {533.333} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.499969} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {187.499969} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__ACT_FREQMHZ {187.499969} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__ACT_FREQMHZ {187.499969} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {33.333328} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__ACT_FREQMHZ {99.999985} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__ACT_FREQMHZ {249.999954} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {19.999996} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3__ENABLE {1} \
    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
    CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    CONFIG.PSU__DDRC__CL {16} \
    CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
    CONFIG.PSU__DDRC__COMPONENTS {Components} \
    CONFIG.PSU__DDRC__CWL {12} \
    CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING {1} \
    CONFIG.PSU__DDRC__DDR4_CAL_MODE_ENABLE {0} \
    CONFIG.PSU__DDRC__DDR4_CRC_CONTROL {0} \
    CONFIG.PSU__DDRC__DDR4_T_REF_MODE {0} \
    CONFIG.PSU__DDRC__DDR4_T_REF_RANGE {Normal (0-85)} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
    CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
    CONFIG.PSU__DDRC__ECC {Disabled} \
    CONFIG.PSU__DDRC__FGRM {1X} \
    CONFIG.PSU__DDRC__LP_ASR {manual normal} \
    CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
    CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
    CONFIG.PSU__DDRC__PER_BANK_REFRESH {0} \
    CONFIG.PSU__DDRC__PHY_DBI_MODE {0} \
    CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
    CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400R} \
    CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
    CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
    CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
    CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
    CONFIG.PSU__DDRC__T_FAW {30.0} \
    CONFIG.PSU__DDRC__T_RAS_MIN {32.0} \
    CONFIG.PSU__DDRC__T_RC {45.32} \
    CONFIG.PSU__DDRC__T_RCD {16} \
    CONFIG.PSU__DDRC__T_RP {16} \
    CONFIG.PSU__DDRC__VREF {1} \
    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
    CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__DLL__ISUSED {1} \
    CONFIG.PSU__ENET1__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET1__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET1__GRP_MDIO__IO {MIO 50 .. 51} \
    CONFIG.PSU__ENET1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET1__PERIPHERAL__IO {MIO 38 .. 49} \
    CONFIG.PSU__ENET1__PTP__ENABLE {0} \
    CONFIG.PSU__ENET1__TSU__ENABLE {0} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__GEM1_COHERENCY {0} \
    CONFIG.PSU__GEM1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM__TSU__ENABLE {0} \
    CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
    CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
    CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO2_MIO__IO {MIO 52 .. 77} \
    CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO_EMIO_WIDTH {41} \
    CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {41} \
    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 18 .. 19} \
    CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 36 .. 37} \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
    CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
    CONFIG.PSU__PL_CLK0_BUF {TRUE} \
    CONFIG.PSU__PMU__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__PRESET_APPLIED {1} \
    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;1|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;1|S_AXI_HPC0_FPD:NA;1|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;0|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;0|SD0:NonSecure;1|SATA1:NonSecure;0|SATA0:NonSecure;0|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;0|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;0|GEM2:NonSecure;0|GEM1:NonSecure;1|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1}\
\
    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;1|LPD;USB3_1;FF9E0000;FF9EFFFF;1|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;1|LPD;UART0;FF000000;FF00FFFF;0|LPD;TTC3;FF140000;FF14FFFF;0|LPD;TTC2;FF130000;FF13FFFF;0|LPD;TTC1;FF120000;FF12FFFF;0|LPD;TTC0;FF110000;FF11FFFF;0|FPD;SWDT1;FD4D0000;FD4DFFFF;0|LPD;SWDT0;FF150000;FF15FFFF;0|LPD;SPI1;FF050000;FF05FFFF;1|LPD;SPI0;FF040000;FF04FFFF;1|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;0|LPD;SD0;FF160000;FF16FFFF;1|FPD;SATA;FD0C0000;FD0CFFFF;0|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;0|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;0|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;0|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;1|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display\
Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1}\
\
    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.33333} \
    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} \
    CONFIG.PSU__SAXIGP1__DATA_WIDTH {128} \
    CONFIG.PSU__SD0_COHERENCY {0} \
    CONFIG.PSU__SD0_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__SD0__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD0__CLK_50_SDR_OTAP_DLY {0x5} \
    CONFIG.PSU__SD0__DATA_TRANSFER_MODE {4Bit} \
    CONFIG.PSU__SD0__GRP_CD__ENABLE {1} \
    CONFIG.PSU__SD0__GRP_CD__IO {MIO 24} \
    CONFIG.PSU__SD0__GRP_POW__ENABLE {0} \
    CONFIG.PSU__SD0__GRP_WP__ENABLE {1} \
    CONFIG.PSU__SD0__GRP_WP__IO {MIO 25} \
    CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 16 21 22} \
    CONFIG.PSU__SD0__SLOT_TYPE {SD 2.0} \
    CONFIG.PSU__SPI0__GRP_SS0__IO {MIO 3} \
    CONFIG.PSU__SPI0__GRP_SS1__ENABLE {1} \
    CONFIG.PSU__SPI0__GRP_SS1__IO {MIO 2} \
    CONFIG.PSU__SPI0__GRP_SS2__ENABLE {1} \
    CONFIG.PSU__SPI0__GRP_SS2__IO {MIO 1} \
    CONFIG.PSU__SPI0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SPI0__PERIPHERAL__IO {MIO 0 .. 5} \
    CONFIG.PSU__SPI1__GRP_SS0__IO {MIO 9} \
    CONFIG.PSU__SPI1__GRP_SS1__ENABLE {0} \
    CONFIG.PSU__SPI1__GRP_SS2__ENABLE {0} \
    CONFIG.PSU__SPI1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SPI1__PERIPHERAL__IO {MIO 6 .. 11} \
    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__UART1__BAUD_RATE {115200} \
    CONFIG.PSU__UART1__MODEM__ENABLE {0} \
    CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART1__PERIPHERAL__IO {MIO 32 .. 33} \
    CONFIG.PSU__USB0_COHERENCY {0} \
    CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
    CONFIG.PSU__USB0__REF_CLK_FREQ {100} \
    CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk1} \
    CONFIG.PSU__USB1_COHERENCY {0} \
    CONFIG.PSU__USB1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB1__PERIPHERAL__IO {MIO 64 .. 75} \
    CONFIG.PSU__USB1__REF_CLK_FREQ {100} \
    CONFIG.PSU__USB1__REF_CLK_SEL {Ref Clk1} \
    CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
    CONFIG.PSU__USB2_1__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_0__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB3_0__PERIPHERAL__IO {GT Lane2} \
    CONFIG.PSU__USB3_1__EMIO__ENABLE {0} \
    CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__USB3_1__PERIPHERAL__IO {GT Lane3} \
    CONFIG.PSU__USB__RESET__MODE {Boot Pin} \
    CONFIG.PSU__USB__RESET__POLARITY {Active Low} \
    CONFIG.PSU__USE__IRQ0 {1} \
    CONFIG.PSU__USE__IRQ1 {1} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__S_AXI_GP0 {1} \
    CONFIG.PSU__USE__S_AXI_GP1 {1} \
  ] $zynq_ultra_ps


  # Create instance: rfdc, and set properties
  set rfdc [ create_bd_cell -type ip -vlnv xilinx.com:ip:usp_rf_data_converter:2.6 rfdc ]
  set_property -dict [list \
    CONFIG.ADC0_Outclk_Freq {46.080} \
    CONFIG.ADC0_PLL_Enable {true} \
    CONFIG.ADC0_Refclk_Freq {491.520} \
    CONFIG.ADC0_Sampling_Rate {1.47456} \
    CONFIG.ADC2_Outclk_Freq {46.080} \
    CONFIG.ADC2_PLL_Enable {true} \
    CONFIG.ADC2_Refclk_Freq {491.520} \
    CONFIG.ADC2_Sampling_Rate {1.47456} \
    CONFIG.ADC_Data_Width00 {12} \
    CONFIG.ADC_Data_Width02 {12} \
    CONFIG.ADC_Data_Width20 {12} \
    CONFIG.ADC_Dither00 {true} \
    CONFIG.ADC_Slice02_Enable {true} \
    CONFIG.ADC_Slice20_Enable {true} \
    CONFIG.DAC_Slice00_Enable {false} \
  ] $rfdc


  # Create instance: rst_ps8_0_99M, and set properties
  set rst_ps8_0_99M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M ]

  # Create instance: global_axi_control, and set properties
  set global_axi_control [ create_bd_cell -type ip -vlnv user.org:user:global_axi_control:1.2 global_axi_control ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {217.01000000000002} \
    CONFIG.CLKIN2_JITTER_PS {149.99} \
    CONFIG.CLKOUT1_DRIVES {Buffer} \
    CONFIG.CLKOUT1_JITTER {139.561} \
    CONFIG.CLKOUT1_PHASE_ERROR {160.206} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {122.88} \
    CONFIG.CLKOUT2_DRIVES {Buffer} \
    CONFIG.CLKOUT3_DRIVES {Buffer} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.CLK_OUT1_PORT {clk_122_88_MHZ} \
    CONFIG.ENABLE_CLOCK_MONITOR {false} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {26.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {21.701} \
    CONFIG.MMCM_CLKIN2_PERIOD {15.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {9.750} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
    CONFIG.OVERRIDE_MMCM {false} \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_INCLK_SWITCHOVER {false} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz


  # Create instance: sync_start, and set properties
  set sync_start [ create_bd_cell -type ip -vlnv user.org:user:external_start_sync:1.0 sync_start ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {12} \
  ] $axi_smc


  # Create instance: zynq_ultra_ps_axi_periph, and set properties
  set zynq_ultra_ps_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 zynq_ultra_ps_axi_periph ]
  set_property CONFIG.NUM_MI {64} $zynq_ultra_ps_axi_periph


  # Create instance: counters, and set properties
  set counters [ create_bd_cell -type ip -vlnv user.org:user:counters:1.1 counters ]

  # Create instance: adc_224_0
  create_hier_cell_adc_224_0 [current_bd_instance .] adc_224_0

  # Create instance: adc_224_1
  create_hier_cell_adc_224_1 [current_bd_instance .] adc_224_1

  # Create instance: adc_226_0
  create_hier_cell_adc_226_0 [current_bd_instance .] adc_226_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {64} \
  ] $xlconstant_0


  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI3_1 [get_bd_intf_pins adc_224_0/S00_AXI3] [get_bd_intf_pins zynq_ultra_ps_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net adc0_clk_1 [get_bd_intf_ports adc0_clk] [get_bd_intf_pins rfdc/adc0_clk]
  connect_bd_intf_net -intf_net adc2_clk_1 [get_bd_intf_ports adc2_clk] [get_bd_intf_pins rfdc/adc2_clk]
  connect_bd_intf_net -intf_net adc_224_1_M_AXI_S2MM [get_bd_intf_pins adc_224_1/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S04_AXI]
  connect_bd_intf_net -intf_net adc_224_1_M_AXI_S2MM1 [get_bd_intf_pins adc_224_1/M_AXI_S2MM1] [get_bd_intf_pins axi_smc/S05_AXI]
  connect_bd_intf_net -intf_net adc_224_1_M_AXI_S2MM2 [get_bd_intf_pins adc_224_1/M_AXI_S2MM2] [get_bd_intf_pins axi_smc/S06_AXI]
  connect_bd_intf_net -intf_net adc_224_1_M_AXI_S2MM3 [get_bd_intf_pins adc_224_1/M_AXI_S2MM3] [get_bd_intf_pins axi_smc/S07_AXI]
  connect_bd_intf_net -intf_net adc_226_0_M_AXI_S2MM [get_bd_intf_pins adc_226_0/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S08_AXI]
  connect_bd_intf_net -intf_net adc_226_0_M_AXI_S2MM1 [get_bd_intf_pins adc_226_0/M_AXI_S2MM1] [get_bd_intf_pins axi_smc/S09_AXI]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins zynq_ultra_ps/S_AXI_HPC0_FPD] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins zynq_ultra_ps/S_AXI_HPC1_FPD]
  connect_bd_intf_net -intf_net lockin_instance_0_M_AXI_S2MM [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins adc_224_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net lockin_instance_1_M_AXI_S2MM [get_bd_intf_pins adc_224_0/M_AXI_S2MM1] [get_bd_intf_pins axi_smc/S01_AXI]
  connect_bd_intf_net -intf_net lockin_instance_2_M_AXI_S2MM [get_bd_intf_pins adc_224_0/M_AXI_S2MM2] [get_bd_intf_pins axi_smc/S02_AXI]
  connect_bd_intf_net -intf_net lockin_instance_3_M_AXI_S2MM [get_bd_intf_pins adc_224_0/M_AXI_S2MM3] [get_bd_intf_pins axi_smc/S03_AXI]
  connect_bd_intf_net -intf_net sysref_in_1 [get_bd_intf_ports sysref_in] [get_bd_intf_pins rfdc/sysref_in]
  connect_bd_intf_net -intf_net vin0_01_1 [get_bd_intf_ports vin0_01] [get_bd_intf_pins rfdc/vin0_01]
  connect_bd_intf_net -intf_net vin0_23_1 [get_bd_intf_ports vin0_23] [get_bd_intf_pins rfdc/vin0_23]
  connect_bd_intf_net -intf_net vin2_01_1 [get_bd_intf_ports vin2_01] [get_bd_intf_pins rfdc/vin2_01]
  connect_bd_intf_net -intf_net zynq_ultra_ps_M_AXI_HPM0_FPD [get_bd_intf_pins zynq_ultra_ps/M_AXI_HPM0_FPD] [get_bd_intf_pins zynq_ultra_ps_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M00_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M00_AXI] [get_bd_intf_pins counters/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M01_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M01_AXI] [get_bd_intf_pins global_axi_control/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M02_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M02_AXI] [get_bd_intf_pins adc_224_0/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M03_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M03_AXI] [get_bd_intf_pins adc_224_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M04_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M04_AXI] [get_bd_intf_pins adc_224_0/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M05_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M05_AXI] [get_bd_intf_pins adc_224_0/S00_AXI2]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M07_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M07_AXI] [get_bd_intf_pins adc_224_0/S00_AXI4]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M08_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M08_AXI] [get_bd_intf_pins adc_224_0/S00_AXI5]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M09_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M09_AXI] [get_bd_intf_pins adc_224_0/S00_AXI6]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M10_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M10_AXI] [get_bd_intf_pins adc_224_0/S00_AXI7]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M11_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M11_AXI] [get_bd_intf_pins adc_224_0/S_AXI_LITE1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M12_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M12_AXI] [get_bd_intf_pins adc_224_0/S00_AXI8]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M13_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M13_AXI] [get_bd_intf_pins adc_224_0/S00_AXI9]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M14_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M14_AXI] [get_bd_intf_pins adc_224_0/S00_AXI10]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M15_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M15_AXI] [get_bd_intf_pins adc_224_0/S00_AXI11]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M16_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M16_AXI] [get_bd_intf_pins adc_224_0/S_AXI_LITE2]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M17_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M17_AXI] [get_bd_intf_pins adc_224_0/S00_AXI12]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M18_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M18_AXI] [get_bd_intf_pins adc_224_0/S00_AXI13]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M19_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M19_AXI] [get_bd_intf_pins adc_224_0/S00_AXI14]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M20_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M20_AXI] [get_bd_intf_pins adc_224_0/S00_AXI15]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M21_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M21_AXI] [get_bd_intf_pins adc_224_0/S_AXI_LITE3]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M22_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M22_AXI] [get_bd_intf_pins adc_224_1/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M23_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M23_AXI] [get_bd_intf_pins adc_224_1/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M24_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M24_AXI] [get_bd_intf_pins adc_224_1/S00_AXI3]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M25_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M25_AXI] [get_bd_intf_pins adc_224_1/S00_AXI2]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M26_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M26_AXI] [get_bd_intf_pins adc_224_1/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M27_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M27_AXI] [get_bd_intf_pins adc_224_1/S00_AXI4]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M28_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M28_AXI] [get_bd_intf_pins adc_224_1/S00_AXI5]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M29_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M29_AXI] [get_bd_intf_pins adc_224_1/S00_AXI6]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M30_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M30_AXI] [get_bd_intf_pins adc_224_1/S00_AXI7]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M31_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M31_AXI] [get_bd_intf_pins adc_224_1/S_AXI_LITE1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M32_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M32_AXI] [get_bd_intf_pins adc_224_1/S00_AXI8]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M33_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M33_AXI] [get_bd_intf_pins adc_224_1/S00_AXI9]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M34_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M34_AXI] [get_bd_intf_pins rfdc/s_axi]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M35_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M35_AXI] [get_bd_intf_pins sync_start/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M36_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M36_AXI] [get_bd_intf_pins adc_224_1/S00_AXI10]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M37_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M37_AXI] [get_bd_intf_pins adc_224_1/S00_AXI11]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M38_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M38_AXI] [get_bd_intf_pins adc_224_1/S_AXI_LITE2]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M39_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M39_AXI] [get_bd_intf_pins adc_224_1/S00_AXI12]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M40_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M40_AXI] [get_bd_intf_pins adc_224_1/S00_AXI13]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M41_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M41_AXI] [get_bd_intf_pins adc_224_1/S00_AXI14]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M42_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M42_AXI] [get_bd_intf_pins adc_224_1/S00_AXI15]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M43_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M43_AXI] [get_bd_intf_pins adc_224_1/S_AXI_LITE3]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M44_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M44_AXI] [get_bd_intf_pins adc_226_0/S00_AXI1]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M45_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M45_AXI] [get_bd_intf_pins adc_226_0/S00_AXI]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M46_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M46_AXI] [get_bd_intf_pins adc_226_0/S00_AXI3]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M47_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M47_AXI] [get_bd_intf_pins adc_226_0/S00_AXI2]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M48_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M48_AXI] [get_bd_intf_pins adc_226_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M49_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M49_AXI] [get_bd_intf_pins adc_226_0/S00_AXI4]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M50_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M50_AXI] [get_bd_intf_pins adc_226_0/S00_AXI5]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M51_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M51_AXI] [get_bd_intf_pins adc_226_0/S00_AXI6]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M52_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M52_AXI] [get_bd_intf_pins adc_226_0/S00_AXI7]
  connect_bd_intf_net -intf_net zynq_ultra_ps_axi_periph_M53_AXI [get_bd_intf_pins zynq_ultra_ps_axi_periph/M53_AXI] [get_bd_intf_pins adc_226_0/S_AXI_LITE1]

  # Create port connections
  connect_bd_net -net adc_224_0_valid_counter_port1 [get_bd_pins adc_224_0/valid_counter_port1] [get_bd_pins counters/counter_01]
  connect_bd_net -net adc_224_0_valid_counter_port2 [get_bd_pins adc_224_0/valid_counter_port2] [get_bd_pins counters/counter_02]
  connect_bd_net -net adc_224_0_valid_counter_port3 [get_bd_pins adc_224_0/valid_counter_port3] [get_bd_pins counters/counter_03]
  connect_bd_net -net adc_224_1_valid_counter_port [get_bd_pins adc_224_1/valid_counter_port] [get_bd_pins counters/counter_04]
  connect_bd_net -net adc_224_1_valid_counter_port1 [get_bd_pins adc_224_1/valid_counter_port1] [get_bd_pins counters/counter_05]
  connect_bd_net -net adc_224_1_valid_counter_port2 [get_bd_pins adc_224_1/valid_counter_port2] [get_bd_pins counters/counter_06]
  connect_bd_net -net adc_224_1_valid_counter_port3 [get_bd_pins adc_224_1/valid_counter_port3] [get_bd_pins counters/counter_07]
  connect_bd_net -net adc_226_0_valid_counter_port [get_bd_pins adc_226_0/valid_counter_port] [get_bd_pins counters/counter_08]
  connect_bd_net -net adc_226_0_valid_counter_port1 [get_bd_pins adc_226_0/valid_counter_port1] [get_bd_pins counters/counter_09]
  connect_bd_net -net clk_wiz_clk_153_6_MHZ [get_bd_pins clk_wiz/clk_122_88_MHZ] [get_bd_pins rfdc/m0_axis_aclk] [get_bd_pins zynq_ultra_ps/saxihpc0_fpd_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins zynq_ultra_ps/saxihpc1_fpd_aclk] [get_bd_pins global_axi_control/clk_adc] [get_bd_pins sync_start/synced_clk] [get_bd_pins axi_smc/aclk] [get_bd_pins adc_224_0/clk] [get_bd_pins adc_224_1/clk] [get_bd_pins adc_226_0/clk] [get_bd_pins rfdc/m2_axis_aclk]
  connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net counters_led_b [get_bd_pins counters/led_b] [get_bd_ports led_b]
  connect_bd_net -net counters_led_g [get_bd_pins counters/led_g] [get_bd_ports led_g]
  connect_bd_net -net counters_led_r [get_bd_pins counters/led_r] [get_bd_ports led_r]
  connect_bd_net -net external_start_sync_0_start [get_bd_pins sync_start/start] [get_bd_pins global_axi_control/ext_start]
  connect_bd_net -net from_pps_0_1 [get_bd_ports from_pps] [get_bd_pins sync_start/from_pps]
  connect_bd_net -net global_axi_control_0_config_port [get_bd_pins global_axi_control/config_port] [get_bd_ports led_config] [get_bd_pins adc_224_0/led_config] [get_bd_pins adc_224_1/led_config] [get_bd_pins adc_226_0/led_config]
  connect_bd_net -net global_axi_control_0_reset [get_bd_pins global_axi_control/reset] [get_bd_ports led_reset] [get_bd_pins adc_224_0/led_reset] [get_bd_pins adc_224_1/led_reset] [get_bd_pins adc_226_0/led_reset]
  connect_bd_net -net lockin_instance_0_valid_counter_port [get_bd_pins adc_224_0/valid_counter_port] [get_bd_pins counters/counter_00]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_smc/aresetn]
  connect_bd_net -net rfdc_clk_adc0 [get_bd_pins rfdc/clk_adc0] [get_bd_pins clk_wiz/clk_in1]
  connect_bd_net -net rfdc_m02_axis_tdata [get_bd_pins rfdc/m02_axis_tdata] [get_bd_pins adc_224_1/adc_data]
  connect_bd_net -net rfdc_m02_axis_tvalid [get_bd_pins rfdc/m02_axis_tvalid] [get_bd_pins adc_224_1/adc_data_valid]
  connect_bd_net -net rfdc_m20_axis_tdata [get_bd_pins rfdc/m20_axis_tdata] [get_bd_pins adc_226_0/adc_data]
  connect_bd_net -net rfdc_m20_axis_tvalid [get_bd_pins rfdc/m20_axis_tvalid] [get_bd_pins adc_226_0/adc_data_valid]
  connect_bd_net -net rst_clk_wiz_0_200M_interconnect_aresetn [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins rfdc/m0_axis_aresetn] [get_bd_pins rfdc/m2_axis_aresetn]
  connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins rfdc/s_axi_aresetn] [get_bd_pins global_axi_control/s00_axi_aresetn] [get_bd_pins sync_start/s00_axi_aresetn] [get_bd_pins zynq_ultra_ps_axi_periph/S00_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M00_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M01_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M02_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M03_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M04_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M05_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M06_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M07_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M08_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M09_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M10_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M11_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M12_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M13_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M14_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M15_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M16_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M17_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M18_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M19_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M20_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M21_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M22_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M23_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M24_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M25_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M26_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M27_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M28_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M29_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M30_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M31_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M32_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M33_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M34_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M35_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M36_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M37_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M38_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M39_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M40_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M41_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M42_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M43_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M44_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M45_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M46_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M47_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M48_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M49_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M50_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M51_ARESETN] [get_bd_pins adc_224_0/axi_resetn] [get_bd_pins adc_224_1/axi_resetn] [get_bd_pins adc_226_0/axi_resetn] [get_bd_pins zynq_ultra_ps_axi_periph/M52_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M53_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M54_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M55_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M56_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M57_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M58_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M59_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M60_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M61_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M62_ARESETN] [get_bd_pins zynq_ultra_ps_axi_periph/M63_ARESETN] [get_bd_pins counters/s00_axi_aresetn]
  connect_bd_net -net run [get_bd_pins global_axi_control/run] [get_bd_ports led_run] [get_bd_pins adc_224_0/led_run] [get_bd_pins adc_224_1/led_run] [get_bd_pins adc_226_0/led_run]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins global_axi_control/resetn] [get_bd_pins adc_224_0/s_axis_aresetn] [get_bd_pins adc_224_1/s_axis_aresetn] [get_bd_pins adc_226_0/s_axis_aresetn]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tdata [get_bd_pins rfdc/m00_axis_tdata] [get_bd_pins adc_224_0/adc_data]
  connect_bd_net -net usp_rf_data_converter_0_m00_axis_tvalid [get_bd_pins rfdc/m00_axis_tvalid] [get_bd_pins adc_224_0/adc_data_valid]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins counters/counter_11] [get_bd_pins counters/counter_10]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins zynq_ultra_ps/pl_clk0] [get_bd_pins zynq_ultra_ps/maxihpm0_fpd_aclk] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk] [get_bd_pins rfdc/s_axi_aclk] [get_bd_pins global_axi_control/s00_axi_aclk] [get_bd_pins sync_start/s00_axi_aclk] [get_bd_pins zynq_ultra_ps_axi_periph/ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/S00_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M00_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M01_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M02_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M03_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M04_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M05_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M06_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M07_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M08_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M09_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M10_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M11_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M12_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M13_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M14_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M15_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M16_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M17_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M18_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M19_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M20_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M21_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M22_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M23_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M24_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M25_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M26_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M27_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M28_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M29_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M30_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M31_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M32_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M33_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M34_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M35_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M36_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M37_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M38_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M39_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M40_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M41_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M42_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M43_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M44_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M45_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M46_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M47_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M48_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M49_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M50_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M51_ACLK] [get_bd_pins adc_224_0/s_axi_lite_aclk] [get_bd_pins adc_224_1/s_axi_lite_aclk] [get_bd_pins adc_226_0/s_axi_lite_aclk] [get_bd_pins zynq_ultra_ps_axi_periph/M52_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M53_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M54_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M55_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M56_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M57_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M58_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M59_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M60_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M61_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M62_ACLK] [get_bd_pins zynq_ultra_ps_axi_periph/M63_ACLK] [get_bd_pins counters/s00_axi_aclk]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins zynq_ultra_ps/pl_resetn0] [get_bd_pins rst_ps8_0_99M/ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0xA0000000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_0/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0050000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_1 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_1/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA00A0000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_2 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_2/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA00F0000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_3 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_3/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0140000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_4 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_0/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0190000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_5 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_1/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA01E0000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_6 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_2/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0230000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_7 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_3/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0280000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_8 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_0/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA02D0000 -range 0x00010000 -with_name SEG_axi_control_0_S00_AXI_reg_9 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_1/axi_control_0/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0010000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_0/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0060000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_1 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_1/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA00B0000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_2 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_2/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0100000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_3 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_3/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0150000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_4 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_0/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA01A0000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_5 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_1/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA01F0000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_6 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_2/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0240000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_7 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_3/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0290000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_8 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_0/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA02E0000 -range 0x00010000 -with_name SEG_axi_control_1_S00_AXI_reg_9 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_1/axi_control_1/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_0/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0070000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_1 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_1/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA00C0000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_2 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_2/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0110000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_3 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_3/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0160000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_4 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_0/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA01B0000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_5 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_1/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0200000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_6 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_2/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0250000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_7 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_3/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA02A0000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_8 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_0/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA02F0000 -range 0x00010000 -with_name SEG_axi_control_2_S00_AXI_reg_9 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_1/axi_control_2/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0030000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_0/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0080000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_1 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_1/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA00D0000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_2 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_2/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0120000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_3 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_3/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0170000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_4 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_0/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA01C0000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_5 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_1/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0210000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_6 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_2/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0260000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_7 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_3/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA02B0000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_8 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_0/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0300000 -range 0x00010000 -with_name SEG_axi_control_3_S00_AXI_reg_9 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_1/axi_control_3/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA03C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs counters/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0040000 -range 0x00010000 -with_name SEG_dma_Reg -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_0/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0090000 -range 0x00010000 -with_name SEG_dma_Reg_1 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_1/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA00E0000 -range 0x00010000 -with_name SEG_dma_Reg_2 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_2/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0130000 -range 0x00010000 -with_name SEG_dma_Reg_3 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_0/group_3/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0180000 -range 0x00010000 -with_name SEG_dma_Reg_4 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_0/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA01D0000 -range 0x00010000 -with_name SEG_dma_Reg_5 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_1/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0220000 -range 0x00010000 -with_name SEG_dma_Reg_6 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_2/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0270000 -range 0x00010000 -with_name SEG_dma_Reg_7 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_224_1/group_3/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA02C0000 -range 0x00010000 -with_name SEG_dma_Reg_8 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_0/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0310000 -range 0x00010000 -with_name SEG_dma_Reg_9 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs adc_226_0/group_1/dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA03D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs global_axi_control/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0xA0400000 -range 0x00040000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs rfdc/s_axi/Reg] -force
  assign_bd_address -offset 0xA03E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps/Data] [get_bd_addr_segs sync_start/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_LOW] -force
  assign_bd_address -offset 0x40000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_LOW] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_0/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_2/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_224_1/group_3/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_226_0/group_0/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP0/HPC0_LPS_OCM]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_DDR_HIGH]
  exclude_bd_addr_seg -offset 0xFF800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces adc_226_0/group_1/dma/Data_S2MM] [get_bd_addr_segs zynq_ultra_ps/SAXIGP1/HPC1_LPS_OCM]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


