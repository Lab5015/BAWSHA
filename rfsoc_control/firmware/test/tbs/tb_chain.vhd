-- xsim testbench of chain_wrapper (the FIR stages shared by a group of 4
-- lock-ins). Needs the chain block design, so it runs in Vivado, not GHDL.
--
-- Reads one 8-channel input set per line from stim_file (48 hex digits,
-- channel 0 in the low 24 bits), applies one set every in_period clocks
-- (fir_x5 output rate) and writes, in out_dir:
--   fir_x5_1.txt .. fir_compiler_x5_2.txt  every FIR output beat: "tdata tlast"
--   out.txt                                 every decimate output word (64 hex)
-- A local checker (tmp/xsim/check_chain.py, not committed) compares them bit-exact with an integer
-- model of the chain.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

entity tb_chain is
  generic (
    stim_file : string  := "stim.txt";
    out_dir   : string  := ".";
    in_period : integer := 30
  );
end entity tb_chain;

architecture sim of tb_chain is

  constant clk_period : time := 8.138 ns;

  signal clk         : std_logic := '0';
  signal aresetn     : std_logic := '0';
  signal reset       : std_logic := '1';
  signal run         : std_logic := '0';
  signal config_port : std_logic := '0';
  signal dec_factor  : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned(1, 24));
  signal in_data     : std_logic_vector(191 downto 0) := (others => '0');
  signal in_valid    : std_logic := '0';
  signal out_data    : std_logic_vector(255 downto 0);
  signal out_valid   : std_logic;
  signal overflow    : std_logic;
  signal sync_error  : std_logic;
  signal done        : boolean := false;

  procedure dump_beat (file f : text; data : std_logic_vector; last : std_logic) is
    variable l : line;
  begin
    hwrite(l, data);
    write(l, string'(" "));
    write(l, last);
    writeline(f, l);
  end procedure dump_beat;

begin

  clk <= not clk after clk_period / 2 when not done;

  dut : entity work.chain_wrapper
    port map (
      aresetn     => aresetn,
      clk         => clk,
      config_port => config_port,
      dec_factor  => dec_factor,
      in_data     => in_data,
      in_valid    => in_valid,
      out_data    => out_data,
      out_valid   => out_valid,
      overflow    => overflow,
      reset       => reset,
      run         => run,
      sync_error  => sync_error
    );

  stimulus : process is
    file     f    : text;
    variable l    : line;
    variable word : std_logic_vector(191 downto 0);
    variable n    : integer := 0;
  begin
    for i in 1 to 20 loop
      wait until rising_edge(clk);
    end loop;
    aresetn <= '1';
    reset   <= '0';
    wait until rising_edge(clk);
    config_port <= '1';
    wait until rising_edge(clk);
    config_port <= '0';
    run         <= '1';
    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;

    file_open(f, stim_file, read_mode);
    while not endfile(f) loop
      readline(f, l);
      hread(l, word);
      in_data  <= word;
      in_valid <= '1';
      wait until rising_edge(clk);
      in_valid <= '0';
      for i in 2 to in_period loop
        wait until rising_edge(clk);
      end loop;
      n := n + 1;
    end loop;
    file_close(f);

    -- let the last beats drain through the pipeline
    for i in 1 to 2000 loop
      wait until rising_edge(clk);
    end loop;
    report "tb_chain: " & integer'image(n) & " input sets, overflow=" & std_logic'image(overflow)
           & " sync_error=" & std_logic'image(sync_error);
    done <= true;
    wait;
  end process stimulus;

  dump : process (clk) is
    alias d1 is << signal .tb_chain.dut.chain_i.fir_x5_1_M_AXIS_DATA_TDATA : std_logic_vector(23 downto 0) >>;
    alias v1 is << signal .tb_chain.dut.chain_i.fir_x5_1_M_AXIS_DATA_TVALID : std_logic >>;
    alias t1 is << signal .tb_chain.dut.chain_i.fir_x5_1_M_AXIS_DATA_TLAST : std_logic >>;
    alias d2 is << signal .tb_chain.dut.chain_i.fir_x5_2_M_AXIS_DATA_TDATA : std_logic_vector(31 downto 0) >>;
    alias v2 is << signal .tb_chain.dut.chain_i.fir_x5_2_M_AXIS_DATA_TVALID : std_logic >>;
    alias t2 is << signal .tb_chain.dut.chain_i.fir_x5_2_M_AXIS_DATA_TLAST : std_logic >>;
    alias d3 is << signal .tb_chain.dut.chain_i.fir_x5_3_M_AXIS_DATA_TDATA : std_logic_vector(31 downto 0) >>;
    alias v3 is << signal .tb_chain.dut.chain_i.fir_x5_3_M_AXIS_DATA_TVALID : std_logic >>;
    alias t3 is << signal .tb_chain.dut.chain_i.fir_x5_3_M_AXIS_DATA_TLAST : std_logic >>;
    alias d4 is << signal .tb_chain.dut.chain_i.fir_x5_4_M_AXIS_DATA_TDATA : std_logic_vector(31 downto 0) >>;
    alias v4 is << signal .tb_chain.dut.chain_i.fir_x5_4_M_AXIS_DATA_TVALID : std_logic >>;
    alias t4 is << signal .tb_chain.dut.chain_i.fir_x5_4_M_AXIS_DATA_TLAST : std_logic >>;
    alias d5 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_M_AXIS_DATA_TDATA : std_logic_vector(31 downto 0) >>;
    alias v5 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_M_AXIS_DATA_TVALID : std_logic >>;
    alias t5 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_M_AXIS_DATA_TLAST : std_logic >>;
    alias d6 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_2_M_AXIS_DATA_TDATA : std_logic_vector(31 downto 0) >>;
    alias v6 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_2_M_AXIS_DATA_TVALID : std_logic >>;
    alias t6 is << signal .tb_chain.dut.chain_i.fir_compiler_x5_2_M_AXIS_DATA_TLAST : std_logic >>;
    file     f1 : text open write_mode is out_dir & "/fir_x5_1.txt";
    file     f2 : text open write_mode is out_dir & "/fir_x5_2.txt";
    file     f3 : text open write_mode is out_dir & "/fir_x5_3.txt";
    file     f4 : text open write_mode is out_dir & "/fir_x5_4.txt";
    file     f5 : text open write_mode is out_dir & "/fir_compiler_x5.txt";
    file     f6 : text open write_mode is out_dir & "/fir_compiler_x5_2.txt";
    file     fo : text open write_mode is out_dir & "/out.txt";
    variable l  : line;
  begin
    if rising_edge(clk) then
      if (v1 = '1') then dump_beat(f1, d1, t1); end if;
      if (v2 = '1') then dump_beat(f2, d2, t2); end if;
      if (v3 = '1') then dump_beat(f3, d3, t3); end if;
      if (v4 = '1') then dump_beat(f4, d4, t4); end if;
      if (v5 = '1') then dump_beat(f5, d5, t5); end if;
      if (v6 = '1') then dump_beat(f6, d6, t6); end if;
      if (out_valid = '1') then
        hwrite(l, out_data);
        writeline(fo, l);
      end if;
    end if;
  end process dump;

end architecture sim;
