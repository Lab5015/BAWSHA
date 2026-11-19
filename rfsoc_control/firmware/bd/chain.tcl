###########################################################################
# Block design "chain": the low-rate part of the lock-in filter chain, shared
# by the 4 lock-ins of a group (one instance per group, see bd/main.tcl).
#
#   in_data (8 x 24 bit: lock-in k I = channel 2k, Q = channel 2k+1)
#     -> tdm_interleave (one AXI-Stream, 8 TDM channels, tlast on channel 7)
#     -> fir_x5_1 .. fir_compiler_x5_2 (FIR Compiler, Number_Channels 8)
#     -> tdm_pack (256-bit word, channel c at bits 32c+31..32c)
#     -> decimate (dec_factor from axi_control_0, gated by run)
#
# Same filters, coefficients and rounding as the per-lock-in chain they replace
# (fw v4), only time-shared. fir_x5_1 rounds to 22 bit because fir_x5_2 takes
# 22-bit data (DSP reduction, see docs/CHANGES_stability.md).
# The interleaver is reset with the FIRs (aresetn), never by the soft reset,
# so the TDM channel order of the FIRs and of the interleaver cannot drift.
###########################################################################

set design_name chain
create_bd_design $design_name
current_bd_design $design_name

foreach mod {tdm_interleave tdm_pack decimate} {
   if { [llength [get_files -quiet -of_objects [get_filesets sources_1] */src/$mod.vhd]] == 0 } {
      error "chain.tcl: module $mod not found in the project sources"
   }
}

# Ports
create_bd_port -dir I -type clk -freq_hz 122880000 clk
create_bd_port -dir I -type rst aresetn
create_bd_port -dir I -type rst reset
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset]
create_bd_port -dir I run
create_bd_port -dir I config_port
create_bd_port -dir I -from 23 -to 0 dec_factor
create_bd_port -dir I -from 191 -to 0 in_data
create_bd_port -dir I in_valid
create_bd_port -dir O -from 255 -to 0 out_data
create_bd_port -dir O out_valid
create_bd_port -dir O overflow
create_bd_port -dir O sync_error
set_property CONFIG.ASSOCIATED_RESET {aresetn:reset} [get_bd_ports clk]

# aresetn is active low, the interleaver and packer resets are active high
set aresetn_inv [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 aresetn_inv ]
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}] $aresetn_inv

set tdm_interleave [ create_bd_cell -type module -reference tdm_interleave tdm_interleave ]
set_property -dict [list CONFIG.n_ch {8} CONFIG.width {24}] $tdm_interleave
set tdm_pack [ create_bd_cell -type module -reference tdm_pack tdm_pack ]
set_property -dict [list CONFIG.n_ch {8} CONFIG.width {32}] $tdm_pack
set decimate [ create_bd_cell -type module -reference decimate decimate ]
set_property -dict [list CONFIG.data_width {256} CONFIG.dec_width {24}] $decimate

# FIR stages: 8 TDM channels each, Sample_Frequency is per channel
  set fir_x5_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x5_1 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {2,0,-4,-10,-13,-11,0,17,35,43,32,0,-47,-91,-107,-78,0,106,198,228,162,0,-210,-386,-437,-304,0,383,693,772,531,0,-652,-1166,-1286,-875,0,1056,1872,2049,1384,0,-1648,-2905,-3163,-2127,0,2514,4421,4804,3227,0,-3819,-6731,-7340,-4956,0,5956,10615,11742,8070,0,-10195,-18821,-21778,-15872,0,24203,52516,79099,98013,104858,98013,79099,52516,24203,0,-15872,-21778,-18821,-10195,0,8070,11742,10615,5956,0,-4956,-7340,-6731,-3819,0,3227,4804,4421,2514,0,-2127,-3163,-2905,-1648,0,1384,2049,1872,1056,0,-875,-1286,-1166,-652,0,531,772,693,383,0,-304,-437,-386,-210,0,162,228,198,106,0,-78,-107,-91,-47,0,32,43,35,17,0,-11,-13,-10,-4,0,2} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {22} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {22} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {4.096} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x5_1

  set fir_x5_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x5_2 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {2,0,-4,-10,-13,-11,0,17,35,43,32,0,-47,-91,-107,-78,0,106,198,228,162,0,-210,-386,-437,-304,0,383,693,772,531,0,-652,-1166,-1286,-875,0,1056,1872,2049,1384,0,-1648,-2905,-3163,-2127,0,2514,4421,4804,3227,0,-3819,-6731,-7340,-4956,0,5956,10615,11742,8070,0,-10195,-18821,-21778,-15872,0,24203,52516,79099,98013,104858,98013,79099,52516,24203,0,-15872,-21778,-18821,-10195,0,8070,11742,10615,5956,0,-4956,-7340,-6731,-3819,0,3227,4804,4421,2514,0,-2127,-3163,-2905,-1648,0,1384,2049,1872,1056,0,-875,-1286,-1166,-652,0,531,772,693,383,0,-304,-437,-386,-210,0,162,228,198,106,0,-78,-107,-91,-47,0,32,43,35,17,0,-11,-13,-10,-4,0,2} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {22} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {32} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {0.8192} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x5_2

  set fir_x5_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x5_3 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {2,0,-4,-10,-13,-11,0,17,35,43,32,0,-47,-91,-107,-78,0,106,198,228,162,0,-210,-386,-437,-304,0,383,693,772,531,0,-652,-1166,-1286,-875,0,1056,1872,2049,1384,0,-1648,-2905,-3163,-2127,0,2514,4421,4804,3227,0,-3819,-6731,-7340,-4956,0,5956,10615,11742,8070,0,-10195,-18821,-21778,-15872,0,24203,52516,79099,98013,104858,98013,79099,52516,24203,0,-15872,-21778,-18821,-10195,0,8070,11742,10615,5956,0,-4956,-7340,-6731,-3819,0,3227,4804,4421,2514,0,-2127,-3163,-2905,-1648,0,1384,2049,1872,1056,0,-875,-1286,-1166,-652,0,531,772,693,383,0,-304,-437,-386,-210,0,162,228,198,106,0,-78,-107,-91,-47,0,32,43,35,17,0,-11,-13,-10,-4,0,2} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {32} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {32} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {0.16384} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x5_3

  set fir_x5_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_x5_4 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {2,0,-4,-10,-13,-11,0,17,35,43,32,0,-47,-91,-107,-78,0,106,198,228,162,0,-210,-386,-437,-304,0,383,693,772,531,0,-652,-1166,-1286,-875,0,1056,1872,2049,1384,0,-1648,-2905,-3163,-2127,0,2514,4421,4804,3227,0,-3819,-6731,-7340,-4956,0,5956,10615,11742,8070,0,-10195,-18821,-21778,-15872,0,24203,52516,79099,98013,104858,98013,79099,52516,24203,0,-15872,-21778,-18821,-10195,0,8070,11742,10615,5956,0,-4956,-7340,-6731,-3819,0,3227,4804,4421,2514,0,-2127,-3163,-2905,-1648,0,1384,2049,1872,1056,0,-875,-1286,-1166,-652,0,531,772,693,383,0,-304,-437,-386,-210,0,162,228,198,106,0,-78,-107,-91,-47,0,32,43,35,17,0,-11,-13,-10,-4,0,2} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {18} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {32} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {32} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {0.032768} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_x5_4

  set fir_compiler_x5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_x5 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {0,0,0,-2,-7,-7,6,27,33,0,-62,-97,-41,100,217,160,-105,-401,-419,0,629,906,362,-857,-1848,-1418,1028,4865,8397,9830,8397,4865,1028,-1418,-1848,-857,362,906,629,0,-419,-401,-105,160,217,100,-41,-97,-62,0,33,27,6,-7,-7,-2,0,0,0} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Inferred} \
    CONFIG.Coefficient_Width {17} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {32} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
    CONFIG.Output_Width {32} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {0.0065536} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_compiler_x5

  set fir_compiler_x5_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_x5_2 ]
  set_property -dict [list \
    CONFIG.Clock_Frequency {122.88} \
    CONFIG.CoefficientVector {0,0,0,0,0,1,1,0,-1,-4,-6,-7,-6,-1,5,14,21,24,20,8,-10,-32,-52,-61,-55,-30,11,61,106,131,124,79,0,-98,-192,-253,-254,-183,-43,141,327,462,497,398,161,-180,-557,-875,-1028,-927,-515,208,1188,2312,3431,4381,5018,5242,5018,4381,3431,2312,1188,208,-515,-927,-1028,-875,-557,-180,161,398,497,462,327,141,-43,-183,-254,-253,-192,-98,0,79,124,131,106,61,11,-30,-55,-61,-52,-32,-10,8,20,24,21,14,5,-1,-6,-7,-6,-4,-1,0,1,1,0,0,0,0,0} \
    CONFIG.Coefficient_Fractional_Bits {0} \
    CONFIG.Coefficient_Sets {1} \
    CONFIG.Coefficient_Sign {Signed} \
    CONFIG.Coefficient_Structure {Symmetric} \
    CONFIG.Coefficient_Width {16} \
    CONFIG.DATA_Has_TLAST {Vector_Framing} \
    CONFIG.Data_Width {32} \
    CONFIG.Decimation_Rate {5} \
    CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
    CONFIG.Filter_Type {Decimation} \
    CONFIG.Has_ARESETn {true} \
    CONFIG.Interpolation_Rate {1} \
    CONFIG.Number_Channels {8} \
    CONFIG.Number_Paths {1} \
    CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
    CONFIG.Output_Width {32} \
    CONFIG.Quantization {Integer_Coefficients} \
    CONFIG.RateSpecification {Frequency_Specification} \
    CONFIG.Sample_Frequency {0.00131072} \
    CONFIG.Zero_Pack_Factor {1} \
  ] $fir_compiler_x5_2

# Streams
connect_bd_intf_net [get_bd_intf_pins tdm_interleave/m_axis] [get_bd_intf_pins fir_x5_1/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_x5_1/M_AXIS_DATA] [get_bd_intf_pins fir_x5_2/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_x5_2/M_AXIS_DATA] [get_bd_intf_pins fir_x5_3/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_x5_3/M_AXIS_DATA] [get_bd_intf_pins fir_x5_4/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_x5_4/M_AXIS_DATA] [get_bd_intf_pins fir_compiler_x5/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_compiler_x5/M_AXIS_DATA] [get_bd_intf_pins fir_compiler_x5_2/S_AXIS_DATA]
connect_bd_intf_net [get_bd_intf_pins fir_compiler_x5_2/M_AXIS_DATA] [get_bd_intf_pins tdm_pack/s_axis]

# Nets
set firs {fir_x5_1 fir_x5_2 fir_x5_3 fir_x5_4 fir_compiler_x5 fir_compiler_x5_2}
connect_bd_net [get_bd_ports clk] [get_bd_pins tdm_interleave/clk] [get_bd_pins tdm_pack/clk] [get_bd_pins decimate/clk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins aresetn_inv/Op1]
connect_bd_net [get_bd_pins aresetn_inv/Res] [get_bd_pins tdm_interleave/reset] [get_bd_pins tdm_pack/reset]
foreach f $firs {
   connect_bd_net [get_bd_ports clk] [get_bd_pins $f/aclk]
   connect_bd_net [get_bd_ports aresetn] [get_bd_pins $f/aresetn]
}
connect_bd_net [get_bd_ports in_data] [get_bd_pins tdm_interleave/in_data]
connect_bd_net [get_bd_ports in_valid] [get_bd_pins tdm_interleave/in_valid]
connect_bd_net [get_bd_pins tdm_interleave/overflow] [get_bd_ports overflow]
connect_bd_net [get_bd_pins tdm_pack/sync_error] [get_bd_ports sync_error]
connect_bd_net [get_bd_pins tdm_pack/out_data] [get_bd_pins decimate/data_in]
connect_bd_net [get_bd_pins tdm_pack/out_valid] [get_bd_pins decimate/valid_in]
connect_bd_net [get_bd_ports reset] [get_bd_pins decimate/reset]
connect_bd_net [get_bd_ports run] [get_bd_pins decimate/run]
connect_bd_net [get_bd_ports config_port] [get_bd_pins decimate/config_port]
connect_bd_net [get_bd_ports dec_factor] [get_bd_pins decimate/dec_factor]
connect_bd_net [get_bd_pins decimate/data_out] [get_bd_ports out_data]
connect_bd_net [get_bd_pins decimate/valid_out] [get_bd_ports out_valid]

validate_bd_design
save_bd_design
