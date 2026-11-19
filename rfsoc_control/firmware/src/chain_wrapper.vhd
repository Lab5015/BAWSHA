-- Wrapper of the "chain" block design (bd/chain.tcl): shared low-rate FIR
-- stages of one group of 4 lock-ins. Used as a module reference in bd/main.tcl.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity chain_wrapper is
  port (
    aresetn : in STD_LOGIC;
    clk : in STD_LOGIC;
    config_port : in STD_LOGIC;
    dec_factor : in STD_LOGIC_VECTOR ( 23 downto 0 );
    in_data : in STD_LOGIC_VECTOR ( 191 downto 0 );
    in_valid : in STD_LOGIC;
    out_data : out STD_LOGIC_VECTOR ( 255 downto 0 );
    out_valid : out STD_LOGIC;
    overflow : out STD_LOGIC;
    reset : in STD_LOGIC;
    run : in STD_LOGIC;
    sync_error : out STD_LOGIC
  );
end chain_wrapper;

architecture STRUCTURE of chain_wrapper is
  component chain is
  port (
    clk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    reset : in STD_LOGIC;
    run : in STD_LOGIC;
    config_port : in STD_LOGIC;
    dec_factor : in STD_LOGIC_VECTOR ( 23 downto 0 );
    in_data : in STD_LOGIC_VECTOR ( 191 downto 0 );
    in_valid : in STD_LOGIC;
    out_data : out STD_LOGIC_VECTOR ( 255 downto 0 );
    out_valid : out STD_LOGIC;
    overflow : out STD_LOGIC;
    sync_error : out STD_LOGIC
  );
  end component chain;
begin
chain_i: component chain
     port map (
      aresetn => aresetn,
      clk => clk,
      config_port => config_port,
      dec_factor(23 downto 0) => dec_factor(23 downto 0),
      in_data(191 downto 0) => in_data(191 downto 0),
      in_valid => in_valid,
      out_data(255 downto 0) => out_data(255 downto 0),
      out_valid => out_valid,
      overflow => overflow,
      reset => reset,
      run => run,
      sync_error => sync_error
    );
end STRUCTURE;
