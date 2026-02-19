-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
-- Date        : Tue Feb 10 10:38:47 2026
-- Host        : 193.206.156.61 running 64-bit Arch Linux
-- Command     : generate_target main_wrapper.bd
-- Design      : main_wrapper
-- Purpose     : IP block netlist
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity main_wrapper is
  port (
    adc0_clk_clk_n   : in    std_logic;
    adc0_clk_clk_p   : in    std_logic;
    from_pps         : in    std_logic;
    led_b            : out   std_logic;
    led_config       : out   std_logic;
    led_g            : out   std_logic;
    led_r            : out   std_logic;
    led_reset        : out   std_logic;
    led_run          : out   std_logic;
    sysref_in_diff_n : in    std_logic;
    sysref_in_diff_p : in    std_logic;
    vin0_01_v_n      : in    std_logic;
    vin0_01_v_p      : in    std_logic
  );
end entity main_wrapper;

architecture structure of main_wrapper is

  component main is
    port (
      sysref_in_diff_n : in    std_logic;
      sysref_in_diff_p : in    std_logic;
      adc0_clk_clk_n   : in    std_logic;
      adc0_clk_clk_p   : in    std_logic;
      vin0_01_v_n      : in    std_logic;
      vin0_01_v_p      : in    std_logic;
      led_r            : out   std_logic;
      led_g            : out   std_logic;
      led_b            : out   std_logic;
      led_run          : out   std_logic;
      led_config       : out   std_logic;
      led_reset        : out   std_logic;
      from_pps         : in    std_logic
    );
  end component main;

begin

  main_i : component main
    port map (
      adc0_clk_clk_n   => adc0_clk_clk_n,
      adc0_clk_clk_p   => adc0_clk_clk_p,
      from_pps         => from_pps,
      led_b            => led_b,
      led_config       => led_config,
      led_g            => led_g,
      led_r            => led_r,
      led_reset        => led_reset,
      led_run          => led_run,
      sysref_in_diff_n => sysref_in_diff_n,
      sysref_in_diff_p => sysref_in_diff_p,
      vin0_01_v_n      => vin0_01_v_n,
      vin0_01_v_p      => vin0_01_v_p
    );

end architecture structure;
