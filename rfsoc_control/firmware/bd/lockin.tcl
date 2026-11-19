
################################################################
# This is a generated script based on design: lockin
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
# source lockin_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# iq_multiplier

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
set design_name lockin

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
xilinx.com:ip:fir_compiler:7.2\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlslice:1.0\
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
iq_multiplier\
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


# Hierarchical cell: double_datapath
proc create_hier_cell_double_datapath { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_double_datapath() - Empty argument(s)!"}
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

  # Create pins
  create_bd_pin -dir I -from 15 -to 0 In0
  create_bd_pin -dir I -from 15 -to 0 In1
  create_bd_pin -dir I s_axis_data_tvalid
  create_bd_pin -dir O m_axis_data_tvalid
  create_bd_pin -dir O -from 23 -to 0 Dout
  create_bd_pin -dir O -from 23 -to 0 Dout1
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst aresetn

  # Create instance: fir_x2, and set properties
  set fir_x2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x2 ]
  set_property -dict [list \
    CONFIG.Channel_Sequence {Basic} \
    CONFIG.Clock_Frequency {300.0} \
    CONFIG.CoefficientVector {-12,0,84,0,-337,0,1008,0,-2693,0,10142, 16384, 10142, 0, -2693, 0, 1008, 0, -337, 0, 84, 0, -12} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {16} \
    CONFIG.ColumnConfig {3} \
    CONFIG.DATA_Has_TLAST {Not_Required} \
    CONFIG.Decimation_Rate {2} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.M_DATA_Has_TUSER {Not_Required} \
    CONFIG.Number_Channels {1} \
    CONFIG.Number_Paths {2} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {22} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Input_Sample_Period} \
    CONFIG.S_DATA_Has_TUSER {Not_Required} \
    CONFIG.SamplePeriod {1} \
    CONFIG.Sample_Frequency {0.001} \
    CONFIG.Select_Pattern {All} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x2


  # Create instance: fir_x3, and set properties
  set fir_x3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x3 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {300.0} \
    CONFIG.CoefficientVector {1, 3, 0, -9, -14, 0, 29, 40, 0, -72, -94, 0, 154, 193, 0, -295, -361, 0, 525, 627, 0, -879, -1032, 0, 1404, 1628, 0, -2170, -2496, 0, 3290, 3775, 0, -4988, -5759, 0, 7817, 9243, 0, -13663, -17428, 0, 35809, 72102, 87382, 72102, 35809, 0, -17428, -13663, 0, 9243, 7817, 0, -5759, -4988, 0, 3775, 3290, 0, -2496, -2170, 0, 1628, 1404, 0, -1032, -879, 0, 627, 525, 0, -361, -295, 0, 193, 154, 0, -94, -72, 0, 40, 29, 0, -14, -9, 0, 3, 1} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.ColumnConfig {8} \
    CONFIG.Data_Width {22} \
    CONFIG.Decimation_Rate {3} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {1} \
    CONFIG.Number_Paths {2} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {22} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Input_Sample_Period} \
    CONFIG.SamplePeriod {2} \
    CONFIG.Sample_Frequency {0.001} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x3


  # Create instance: fir_x5, and set properties
  set fir_x5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x5 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {300.0} \
    CONFIG.CoefficientVector {2,  0,  -4,  -10,  -13,  -11,  0,  17,  35,  43,  32,  0,  -47,  -91,  -107,  -78,  0,  106,  198,  228,  162,  0,  -210,  -386,  -437,  -304,  0,  383,  693,  772,  531,\
 0,  -652,  -1166,  -1286,  -875,  0,  1056,  1872,  2049,  1384,  0,  -1648,  -2905,  -3163,  -2127,  0,  2514,  4421,  4804,  3227,  0,  -3819,  -6731,  -7340,  -4956,  0,  5956,  10615,  11742,  8070,\
 0,  -10195,  -18821,  -21778,  -15872,  0,  24203,  52516,  79099,  98013,  104858,  98013,  79099,  52516,  24203,  0,  -15872,  -21778,  -18821,  -10195,  0,  8070,  11742,  10615,  5956,  0,  -4956,\
 -7340,  -6731,  -3819,  0,  3227,  4804,  4421,  2514,  0,  -2127,  -3163,  -2905,  -1648,  0,  1384,  2049,  1872,  1056,  0,  -875,  -1286,  -1166,  -652,  0,  531,  772,  693,  383,  0,  -304,  -437,\
 -386,  -210,  0,  162,  228,  198,  106,  0,  -78,  -107,  -91,  -47,  0,  32,  43,  35,  17,  0,  -11,  -13,  -10,  -4,  0,  2} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.ColumnConfig {3} \
    CONFIG.Data_Width {22} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {1} \
    CONFIG.Number_Paths {2} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {22} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Input_Sample_Period} \
    CONFIG.SamplePeriod {6} \
    CONFIG.Sample_Frequency {0.001} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x5


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {16} \
  ] $xlconcat_0


  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {23} \
    CONFIG.DIN_TO {0} \
    CONFIG.DIN_WIDTH {48} \
    CONFIG.DOUT_WIDTH {24} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {47} \
    CONFIG.DIN_TO {24} \
    CONFIG.DIN_WIDTH {48} \
    CONFIG.DOUT_WIDTH {24} \
  ] $xlslice_1


  # Create interface connections
  connect_bd_intf_net -intf_net fir_x2_M_AXIS_DATA [get_bd_intf_pins fir_x2/M_AXIS_DATA] [get_bd_intf_pins fir_x3/S_AXIS_DATA]
  connect_bd_intf_net -intf_net fir_x3_M_AXIS_DATA [get_bd_intf_pins fir_x3/M_AXIS_DATA] [get_bd_intf_pins fir_x5/S_AXIS_DATA]

  # Create port connections
  connect_bd_net -net In0_1 [get_bd_pins In0] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net In1_1 [get_bd_pins In1] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net Net [get_bd_pins aresetn] [get_bd_pins fir_x5/aresetn] [get_bd_pins fir_x3/aresetn] [get_bd_pins fir_x2/aresetn]
  connect_bd_net -net Net1 [get_bd_pins clk] [get_bd_pins fir_x5/aclk] [get_bd_pins fir_x3/aclk] [get_bd_pins fir_x2/aclk]
  connect_bd_net -net fir_x5_m_axis_data_tdata [get_bd_pins fir_x5/m_axis_data_tdata] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net fir_x5_m_axis_data_tvalid [get_bd_pins fir_x5/m_axis_data_tvalid] [get_bd_pins m_axis_data_tvalid]
  connect_bd_net -net s_axis_data_tvalid_1 [get_bd_pins s_axis_data_tvalid] [get_bd_pins fir_x2/s_axis_data_tvalid]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins xlconcat_0/dout] [get_bd_pins fir_x2/s_axis_data_tdata]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins xlslice_0/Dout] [get_bd_pins Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins xlslice_1/Dout] [get_bd_pins Dout1]

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

  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 122880000 clk ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set config_port [ create_bd_port -dir I config_port ]
  set init_freq [ create_bd_port -dir I -from 31 -to 0 init_freq ]
  set init_phase [ create_bd_port -dir I -from 31 -to 0 init_phase ]
  set adc_data [ create_bd_port -dir I -from 15 -to 0 adc_data ]
  set adc_data_valid [ create_bd_port -dir I adc_data_valid ]
  set output_I [ create_bd_port -dir O -from 23 -to 0 output_I ]
  set output_Q [ create_bd_port -dir O -from 23 -to 0 output_Q ]
  set output_valid [ create_bd_port -dir O output_valid ]
  set run [ create_bd_port -dir I run ]
  set dds_output [ create_bd_port -dir O -from 15 -to 0 dds_output ]
  set dds_valid [ create_bd_port -dir O dds_valid ]
  set aresetn [ create_bd_port -dir I -type rst aresetn ]

  # Create instance: iq_multiplier, and set properties
  set block_name iq_multiplier
  set block_cell_name iq_multiplier
  if { [catch {set iq_multiplier [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $iq_multiplier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: double_datapath
  create_hier_cell_double_datapath [current_bd_instance .] double_datapath

  # Create port connections
  connect_bd_net -net adc_data_0_1 [get_bd_ports adc_data] [get_bd_pins iq_multiplier/adc_data]
  connect_bd_net -net adc_data_valid_0_1 [get_bd_ports adc_data_valid] [get_bd_pins iq_multiplier/adc_data_valid]
  connect_bd_net -net aresetn_1 [get_bd_ports aresetn] [get_bd_pins double_datapath/aresetn]
  connect_bd_net -net clk_0_1 [get_bd_ports clk] [get_bd_pins iq_multiplier/clk] [get_bd_pins double_datapath/clk]
  connect_bd_net -net config_0_1 [get_bd_ports config_port] [get_bd_pins iq_multiplier/config_port]
  connect_bd_net -net double_datapath_Dout [get_bd_pins double_datapath/Dout] [get_bd_ports output_Q]
  connect_bd_net -net double_datapath_Dout1 [get_bd_pins double_datapath/Dout1] [get_bd_ports output_I]
  connect_bd_net -net double_datapath_m_axis_data_tvalid [get_bd_pins double_datapath/m_axis_data_tvalid] [get_bd_ports output_valid]
  connect_bd_net -net init_freq_0_1 [get_bd_ports init_freq] [get_bd_pins iq_multiplier/init_freq]
  connect_bd_net -net init_phase_0_1 [get_bd_ports init_phase] [get_bd_pins iq_multiplier/init_phase]
  connect_bd_net -net iq_multiplier_dds_output [get_bd_pins iq_multiplier/dds_output] [get_bd_ports dds_output]
  connect_bd_net -net iq_multiplier_dds_valid [get_bd_pins iq_multiplier/dds_valid] [get_bd_ports dds_valid]
  connect_bd_net -net iq_multiplier_out_data_i [get_bd_pins iq_multiplier/out_data_i] [get_bd_pins double_datapath/In0]
  connect_bd_net -net iq_multiplier_out_data_valid [get_bd_pins iq_multiplier/out_data_valid] [get_bd_pins double_datapath/s_axis_data_tvalid]
  connect_bd_net -net reset_0_1 [get_bd_ports reset] [get_bd_pins iq_multiplier/reset]
  connect_bd_net -net run_0_1 [get_bd_ports run] [get_bd_pins iq_multiplier/run]
  connect_bd_net -net s_axis_data_tdata_1 [get_bd_pins iq_multiplier/out_data_q] [get_bd_pins double_datapath/In1]

  # Create address segments


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


