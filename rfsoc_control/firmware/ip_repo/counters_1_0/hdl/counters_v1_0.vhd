library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counters_v1_0 is
	generic (
		-- Users to add parameters here
        
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here

        counter_00 : in   std_logic_vector(63 downto 0);
        counter_01 : in   std_logic_vector(63 downto 0);
        counter_02 : in   std_logic_vector(63 downto 0);
        counter_03 : in   std_logic_vector(63 downto 0);
        counter_04 : in   std_logic_vector(63 downto 0);
        counter_05 : in   std_logic_vector(63 downto 0);
        counter_06 : in   std_logic_vector(63 downto 0);
        counter_07 : in   std_logic_vector(63 downto 0);
        counter_08 : in   std_logic_vector(63 downto 0);
        counter_09 : in   std_logic_vector(63 downto 0);
        counter_10 : in   std_logic_vector(63 downto 0);
        counter_11 : in   std_logic_vector(63 downto 0);
--        counter_12 : in   std_logic_vector(63 downto 0);
--        counter_13 : in   std_logic_vector(63 downto 0);
--        counter_14 : in   std_logic_vector(63 downto 0);
--        counter_15 : in   std_logic_vector(63 downto 0);              
--        counter_16 : in   std_logic_vector(63 downto 0);
--        counter_17 : in   std_logic_vector(63 downto 0);
--        counter_18 : in   std_logic_vector(63 downto 0);
--        counter_19 : in   std_logic_vector(63 downto 0);
--        counter_20 : in   std_logic_vector(63 downto 0);
--        counter_21 : in   std_logic_vector(63 downto 0);
--        counter_22 : in   std_logic_vector(63 downto 0);
--        counter_23 : in   std_logic_vector(63 downto 0);
--        counter_24 : in   std_logic_vector(63 downto 0);
--        counter_25 : in   std_logic_vector(63 downto 0);
--        counter_26 : in   std_logic_vector(63 downto 0);
--        counter_27 : in   std_logic_vector(63 downto 0);
--        counter_28 : in   std_logic_vector(63 downto 0);
--        counter_29 : in   std_logic_vector(63 downto 0);
--        counter_30 : in   std_logic_vector(63 downto 0);
--        counter_31 : in   std_logic_vector(63 downto 0);
        
        led_r   : out   std_logic;
        led_g   : out   std_logic;
        led_b   : out   std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end counters_v1_0;

architecture arch_imp of counters_v1_0 is

  constant zero : std_logic_vector(63 downto 0) := (others => '0');
  signal data_lost : std_logic := '0';

	-- component declaration
	component counters_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
		);
		port (
        counter_00 : in   std_logic_vector(63 downto 0);
        counter_01 : in   std_logic_vector(63 downto 0);
        counter_02 : in   std_logic_vector(63 downto 0);
        counter_03 : in   std_logic_vector(63 downto 0);
        counter_04 : in   std_logic_vector(63 downto 0);
        counter_05 : in   std_logic_vector(63 downto 0);
        counter_06 : in   std_logic_vector(63 downto 0);
        counter_07 : in   std_logic_vector(63 downto 0);
        counter_08 : in   std_logic_vector(63 downto 0);
        counter_09 : in   std_logic_vector(63 downto 0);
        counter_10 : in   std_logic_vector(63 downto 0);
        counter_11 : in   std_logic_vector(63 downto 0);
--        counter_12 : in   std_logic_vector(63 downto 0);
--        counter_13 : in   std_logic_vector(63 downto 0);
--        counter_14 : in   std_logic_vector(63 downto 0);
--        counter_15 : in   std_logic_vector(63 downto 0);              
--        counter_16 : in   std_logic_vector(63 downto 0);
--        counter_17 : in   std_logic_vector(63 downto 0);
--        counter_18 : in   std_logic_vector(63 downto 0);
--        counter_19 : in   std_logic_vector(63 downto 0);
--        counter_20 : in   std_logic_vector(63 downto 0);
--        counter_21 : in   std_logic_vector(63 downto 0);
--        counter_22 : in   std_logic_vector(63 downto 0);
--        counter_23 : in   std_logic_vector(63 downto 0);
--        counter_24 : in   std_logic_vector(63 downto 0);
--        counter_25 : in   std_logic_vector(63 downto 0);
--        counter_26 : in   std_logic_vector(63 downto 0);
--        counter_27 : in   std_logic_vector(63 downto 0);
--        counter_28 : in   std_logic_vector(63 downto 0);
--        counter_29 : in   std_logic_vector(63 downto 0);
--        counter_30 : in   std_logic_vector(63 downto 0);
--        counter_31 : in   std_logic_vector(63 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component counters_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
counters_v1_0_S00_AXI_inst : counters_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready,
		
		counter_00 => counter_00,
		counter_01 => counter_01,
		counter_02 => counter_02,
		counter_03 => counter_03,
		counter_04 => counter_04,
		counter_05 => counter_05,
		counter_06 => counter_06,
		counter_07 => counter_07,
		counter_08 => counter_08,
		counter_09 => counter_09,
		counter_10 => counter_10,
		counter_11 => counter_11
--		counter_12 => counter_12,
--		counter_13 => counter_13,
--		counter_14 => counter_14,
--		counter_15 => counter_15,
--		counter_16 => counter_16,
--		counter_17 => counter_17,
--		counter_18 => counter_18,
--		counter_19 => counter_19,
--		counter_20 => counter_20,
--		counter_21 => counter_21,
--		counter_22 => counter_22,
--		counter_23 => counter_23,
--		counter_24 => counter_24,
--		counter_25 => counter_25,
--		counter_26 => counter_26,
--		counter_27 => counter_27,
--		counter_28 => counter_28,
--		counter_29 => counter_29,
--		counter_30 => counter_30,
--		counter_31 => counter_31

	);

	-- Add user logic here
  data_lost <= '1' when counter_00 /= zero else
               '1' when counter_01 /= zero else
               '1' when counter_02 /= zero else
               '1' when counter_03 /= zero else
               '1' when counter_04 /= zero else
               '1' when counter_05 /= zero else
               '1' when counter_06 /= zero else
               '1' when counter_07 /= zero else
               '1' when counter_08 /= zero else
               '1' when counter_09 /= zero else
               '1' when counter_10 /= zero else
               '1' when counter_11 /= zero else
--               '1' when counter_12 /= zero else
--               '1' when counter_13 /= zero else
--               '1' when counter_14 /= zero else
--               '1' when counter_15 /= zero else
--               '1' when counter_16 /= zero else
--               '1' when counter_17 /= zero else
--               '1' when counter_18 /= zero else
--               '1' when counter_19 /= zero else
--               '1' when counter_20 /= zero else
--               '1' when counter_21 /= zero else
--               '1' when counter_22 /= zero else
--               '1' when counter_23 /= zero else
--               '1' when counter_24 /= zero else
--               '1' when counter_25 /= zero else
--               '1' when counter_26 /= zero else
--               '1' when counter_27 /= zero else
--               '1' when counter_28 /= zero else
--               '1' when counter_29 /= zero else
--               '1' when counter_30 /= zero else
--               '1' when counter_31 /= zero else
               '0';
               
  led_r     <= data_lost;
  led_b     <= '0';
  led_g     <= not data_lost;
	-- User logic ends

end arch_imp;
