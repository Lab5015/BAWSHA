--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
--Date        : Wed Jul  8 10:12:21 2026
--Host        : 193.206.156.61 running 64-bit Arch Linux
--Command     : generate_target lockin_wrapper.bd
--Design      : lockin_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity lockin_wrapper is
  port (
    adc_data : in STD_LOGIC_VECTOR ( 15 downto 0 );
    adc_data_valid : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    clk : in STD_LOGIC;
    config_port : in STD_LOGIC;
    dds_output : out STD_LOGIC_VECTOR ( 15 downto 0 );
    dds_valid : out STD_LOGIC;
    dec_factor : in STD_LOGIC_VECTOR ( 23 downto 0 );
    init_freq : in STD_LOGIC_VECTOR ( 31 downto 0 );
    init_phase : in STD_LOGIC_VECTOR ( 31 downto 0 );
    output_I : out STD_LOGIC_VECTOR ( 31 downto 0 );
    output_Q : out STD_LOGIC_VECTOR ( 31 downto 0 );
    output_valid : out STD_LOGIC;
    reset : in STD_LOGIC;
    run : in STD_LOGIC
  );
end lockin_wrapper;

architecture STRUCTURE of lockin_wrapper is
  component lockin is
  port (
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    config_port : in STD_LOGIC;
    init_freq : in STD_LOGIC_VECTOR ( 31 downto 0 );
    init_phase : in STD_LOGIC_VECTOR ( 31 downto 0 );
    adc_data : in STD_LOGIC_VECTOR ( 15 downto 0 );
    adc_data_valid : in STD_LOGIC;
    output_I : out STD_LOGIC_VECTOR ( 31 downto 0 );
    output_Q : out STD_LOGIC_VECTOR ( 31 downto 0 );
    output_valid : out STD_LOGIC;
    run : in STD_LOGIC;
    dec_factor : in STD_LOGIC_VECTOR ( 23 downto 0 );
    dds_output : out STD_LOGIC_VECTOR ( 15 downto 0 );
    dds_valid : out STD_LOGIC;
    aresetn : in STD_LOGIC
  );
  end component lockin;
begin
lockin_i: component lockin
     port map (
      adc_data(15 downto 0) => adc_data(15 downto 0),
      adc_data_valid => adc_data_valid,
      aresetn => aresetn,
      clk => clk,
      config_port => config_port,
      dds_output(15 downto 0) => dds_output(15 downto 0),
      dds_valid => dds_valid,
      dec_factor(23 downto 0) => dec_factor(23 downto 0),
      init_freq(31 downto 0) => init_freq(31 downto 0),
      init_phase(31 downto 0) => init_phase(31 downto 0),
      output_I(31 downto 0) => output_I(31 downto 0),
      output_Q(31 downto 0) => output_Q(31 downto 0),
      output_valid => output_valid,
      reset => reset,
      run => run
    );
end STRUCTURE;
