library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use ieee.std_logic_textio.all;

entity tb_top is
  generic (
    clk_period : time := 5 ns;

    packets_width : integer := 10;
    axi_width     : integer := 32;
    pac_width     : integer := 32;
    adc_width     : integer := 16;
    s_per_cycle   : integer := 12;
    dec_width     : integer := 24;
    out_width     : integer := 32;

    num_inputs  : integer := 40000000;
    num_results : integer := 39745
  );
end entity tb_top;

architecture rtl of tb_top is

  component lockin_wrapper is
    port (
      clk         : in    std_logic;
      reset       : in    std_logic;
      run         : in    std_logic;
      config_port : in    std_logic;

      adc_data       : in    std_logic_vector(adc_width * s_per_cycle - 1 downto 0);
      adc_data_valid : in    std_logic;
      active_port    : in    std_logic_vector(axi_width - 1 downto 0);

      dec_factor : in    std_logic_vector(axi_width - 1 downto 0);
      init_freq  : in    std_logic_vector(axi_width - 1 downto 0);
      init_phase : in    std_logic_vector(axi_width - 1 downto 0);

      dds_tdata  : out   std_logic_vector(15 downto 0);
      dds_tvalid : out   std_logic;

      output_i     : out   std_logic_vector(out_width - 1 downto 0);
      output_q     : out   std_logic_vector(out_width - 1 downto 0);
      output_valid : out   std_logic
    );
  end component lockin_wrapper;

  component tlast_gen is
    generic (
      packets_width : integer := packets_width
    );
    port (
      clk    : in    std_logic;
      reset  : in    std_logic;
      resetn : in    std_logic;

      out_ready : in    std_logic;

      in_data_i : in    std_logic_vector(31 downto 0);
      in_data_q : in    std_logic_vector(31 downto 0);
      in_valid  : in    std_logic;

      out_data_i : out   std_logic_vector(31 downto 0);
      out_data_q : out   std_logic_vector(31 downto 0);
      out_tlast  : out   std_logic;
      out_valid  : out   std_logic;

      data_lost_port : out   std_logic_vector(31 downto 0)
    );
  end component tlast_gen;

  -- end components

  signal clk : std_logic := '1';

  -- inputs
  signal frequency   : std_logic_vector(axi_width - 1 downto 0) := (others => '0');
  signal phase       : std_logic_vector(axi_width - 1 downto 0) := (others => '0');
  signal mov_size    : std_logic_vector(axi_width - 1 downto 0) := (others => '0');
  signal num_tlast   : std_logic_vector(axi_width - 1 downto 0) := (others => '0');
  signal dec_factor  : std_logic_vector(axi_width - 1 downto 0) := (others => '0');
  signal active_port : std_logic_vector(axi_width - 1 downto 0) := (others => '1');

  signal adc_data       : std_logic_vector(adc_width * s_per_cycle - 1 downto 0) := (others => '0');
  signal adc_data_valid : std_logic                                              := '1';

  -- intermediate
  signal reset       : std_logic := '0';
  signal resetn      : std_logic := '1';
  signal config_port : std_logic := '0';
  signal run         : std_logic := '0';

  signal output_i : std_logic_vector(out_width - 1 downto 0);
  signal output_q : std_logic_vector(out_width - 1 downto 0);
  signal out_val  : std_logic;

  -- outputs
  signal out_data_i     : std_logic_vector(out_width - 1 downto 0);
  signal out_data_q     : std_logic_vector(out_width - 1 downto 0);
  signal out_tlast      : std_logic;
  signal out_tvalid     : std_logic;
  signal dds_tdata      : std_logic_vector(15 downto 0);
  signal dds_tvalid     : std_logic;
  signal data_lost_port : std_logic_vector(31 downto 0);

  -- simulation signals

  type in_data_type is array(0 to num_inputs - 1) of std_logic_vector(adc_width - 1 downto 0);

  type type_results is array(0 to num_results - 1) of signed(out_width - 1 downto 0);

  signal counter             : integer   := 0;
  file   stim_file           : text;
  file   output_file         : text;
  signal file_wrote          : std_logic := '0';
  signal input_data_tdata    : in_data_type;
  signal effective_results_i : type_results;
  signal effective_results_q : type_results;

begin

  inst_lockin : component lockin_wrapper
    port map (
      clk            => clk,
      reset          => reset,
      run            => run,
      config_port    => config_port,
      adc_data       => adc_data,
      adc_data_valid => adc_data_valid,
      active_port    => active_port,
      dds_tdata      => dds_tdata,
      dds_tvalid     => dds_tvalid,
      dec_factor     => dec_factor,
      init_freq      => frequency,
      init_phase     => phase,
      output_i       => output_i,
      output_q       => output_q,
      output_valid   => out_val
    );

  inst_tlast_gen : component tlast_gen
    generic map (
      packets_width => packets_width
    )
    port map (
      clk            => clk,
      reset          => reset,
      resetn         => resetn,
      out_ready      => '1',
      in_data_i      => output_i,
      in_data_q      => output_q,
      in_valid       => out_val,
      out_data_i     => out_data_i,
      out_data_q     => out_data_q,
      out_tlast      => out_tlast,
      out_valid      => out_tvalid,
      data_lost_port => data_lost_port
    );

  -- Clock process
  clk <= not clk after clk_period / 2;

      -- Stimulus processes
    stim_process : process
        variable text_line : line;
        variable var_adc_data : std_logic_vector(adc_width - 1 downto 0);
        variable var_axi_width_len : std_logic_vector(axi_width - 1 downto 0);
    begin
        -- reset
        reset <= '1';
        wait for 10 * clk_period;
        reset <= '0';
    
        file_open(stim_file, "stimuli.txt", read_mode);
    
        -- read configuration
        readline(stim_file, text_line);
        read(text_line, var_axi_width_len); frequency   <= var_axi_width_len;
        read(text_line, var_axi_width_len); phase       <= var_axi_width_len;
        read(text_line, var_axi_width_len); num_tlast   <= var_axi_width_len;
        read(text_line, var_axi_width_len); dec_factor  <= var_axi_width_len;
    
        -- config pulse
        config_port <= '1';
        wait for 10 * clk_period;
        config_port <= '0';
    
        -- start
        run <= '1';
        wait for clk_period;
    
        -- stream samples one by one
        for i in 0 to num_inputs - 1 loop
            readline(stim_file, text_line);
            read(text_line, var_adc_data);
    
            adc_data(adc_width - 1 downto 0) <= var_adc_data;
            adc_data_valid <= '1';
    
            wait until rising_edge(clk);
        end loop;
    
        file_close(stim_file);
    
        report "All input samples sent";
        wait;
    end process;

  check_results : process (clk) is

    variable result_line : line;

  begin

    if (rising_edge(clk)) then
      if (out_tvalid = '1') then
        counter <= counter + 1;
      end if;
      if (counter < num_results and out_tvalid = '1') then
        effective_results_i(counter) <= signed(out_data_i);
        effective_results_q(counter) <= signed(out_data_q);
      elsif (counter = num_results and file_wrote = '0') then
        file_open(output_file, "effective_results.txt", write_mode);

        for i in effective_results_i'range loop

          write(result_line, integer'image(to_integer(signed(effective_results_i(i)))));
          writeline(output_file, result_line);

        end loop;

        for i in effective_results_q'range loop

          write(result_line, integer'image(to_integer(signed(effective_results_q(i)))));
          writeline(output_file, result_line);

        end loop;

        file_close(output_file);
        report "Output file written";
        file_wrote <= '1';
      end if;
    end if;

  end process check_results;

end architecture rtl;
