set_false_path -to [get_ports led*]
set_output_delay 0.000 [get_ports led*]

set_property PACKAGE_PIN AR11 [get_ports led_reset]
set_property IOSTANDARD LVCMOS18 [get_ports led_reset]

set_property PACKAGE_PIN AW10 [get_ports led_config]
set_property IOSTANDARD LVCMOS18 [get_ports led_config]

set_property PACKAGE_PIN AT11 [get_ports led_run]
set_property IOSTANDARD LVCMOS18 [get_ports led_run]

set_property PACKAGE_PIN AM8 [get_ports led_r]
set_property IOSTANDARD LVCMOS18 [get_ports led_r]

set_property PACKAGE_PIN AM7 [get_ports led_g]
set_property IOSTANDARD LVCMOS18 [get_ports led_g]

set_property PACKAGE_PIN AN8 [get_ports led_b]
set_property IOSTANDARD LVCMOS18 [get_ports led_b]

set_property PACKAGE_PIN AJ13 [ get_ports from_pps]
set_property IOSTANDARD LVCMOS18 [ get_ports from_pps]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
