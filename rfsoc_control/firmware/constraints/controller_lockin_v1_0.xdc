set_false_path -from [get_pins -hierarchical slv_reg*/C]
set_false_path -to [get_pins -hierarchical slv_reg*/D]
set_false_path -to [get_pins -hierarchical {axi_rdata_reg[*]/D}]
