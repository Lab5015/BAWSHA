-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
-- Date        : Tue Feb 10 10:16:36 2026
-- Host        : 193.206.156.61 running 64-bit Arch Linux
-- Command     : generate_target lockin_wrapper.bd
-- Design      : lockin_wrapper
-- Purpose     : IP block netlist
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity lockin_wrapper is
  port (
    active_port    : in    std_logic_vector( 31 downto 0);
    adc_data       : in    std_logic_vector( 15 downto 0);
    adc_data_valid : in    std_logic;
    aresetn        : in    std_logic;
    clk            : in    std_logic;
    config_port    : in    std_logic;
    dds_output     : out   std_logic_vector( 15 downto 0);
    dds_valid      : out   std_logic;
    dec_factor     : in    std_logic_vector( 23 downto 0);
    init_freq      : in    std_logic_vector( 31 downto 0);
    init_phase     : in    std_logic_vector( 31 downto 0);
    output_i       : out   std_logic_vector( 31 downto 0);
    output_q       : out   std_logic_vector( 31 downto 0);
    output_valid   : out   std_logic;
    reset          : in    std_logic;
    run            : in    std_logic
  );
end entity lockin_wrapper;

architecture structure of lockin_wrapper is

  component lockin is
    port (
      clk            : in    std_logic;
      reset          : in    std_logic;
      config_port    : in    std_logic;
      init_freq      : in    std_logic_vector( 31 downto 0);
      init_phase     : in    std_logic_vector( 31 downto 0);
      adc_data       : in    std_logic_vector( 15 downto 0);
      adc_data_valid : in    std_logic;
      output_i       : out   std_logic_vector( 31 downto 0);
      output_q       : out   std_logic_vector( 31 downto 0);
      output_valid   : out   std_logic;
      run            : in    std_logic;
      dec_factor     : in    std_logic_vector( 23 downto 0);
      active_port    : in    std_logic_vector( 31 downto 0);
      dds_output     : out   std_logic_vector( 15 downto 0);
      dds_valid      : out   std_logic;
      aresetn        : in    std_logic
    );
  end component lockin;

begin

  lockin_i : component lockin
    port map (
      active_port(31 downto 0) => active_port(31 downto 0),
      adc_data(15 downto 0)    => adc_data(15 downto 0),
      adc_data_valid           => adc_data_valid,
      aresetn                  => aresetn,
      clk                      => clk,
      config_port              => config_port,
      dds_output(15 downto 0)  => dds_output(15 downto 0),
      dds_valid                => dds_valid,
      dec_factor(23 downto 0)  => dec_factor(23 downto 0),
      init_freq(31 downto 0)   => init_freq(31 downto 0),
      init_phase(31 downto 0)  => init_phase(31 downto 0),
      output_i(31 downto 0)    => output_i(31 downto 0),
      output_q(31 downto 0)    => output_q(31 downto 0),
      output_valid             => output_valid,
      reset                    => reset,
      run                      => run
    );

end architecture structure;
