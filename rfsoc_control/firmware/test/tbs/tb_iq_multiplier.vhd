
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use ieee.std_logic_textio.all;

entity tb_iq_multiplier is
  generic (
    clk_period : time    := 5 ns;
    out_width  : integer := 16;
    pac_width  : integer := 32;
    gen_width  : integer := 18;
    adc_width  : integer := 16;

    num_samples : integer := 10_000
  );
end entity tb_iq_multiplier;

architecture rtl of tb_iq_multiplier is

  component iq_multiplier is
    generic (
      pac_width : integer := pac_width;
      gen_width : integer := gen_width;
      adc_width : integer := adc_width;
      out_width : integer := out_width
    );
    port (
      clk            : in    std_logic;
      reset          : in    std_logic;
      run            : in    std_logic;
      config_port    : in    std_logic;
      init_freq      : in    std_logic_vector(pac_width - 1 downto 0);
      init_phase     : in    std_logic_vector(pac_width - 1 downto 0);
      adc_data       : in    std_logic_vector(adc_width - 1 downto 0);
      adc_data_valid : in    std_logic;
      out_data_i     : out   std_logic_vector(out_width - 1 downto 0);
      out_data_q     : out   std_logic_vector(out_width - 1 downto 0);
      out_data_valid : out   std_logic
    );
  end component iq_multiplier;

  signal clk            : std_logic                                := '1';
  signal reset          : std_logic                                := '0';
  signal config_port    : std_logic                                := '0';
  signal run            : std_logic                                := '0';
  signal init_freq      : unsigned(pac_width - 1 downto 0);
  signal init_phase     : unsigned(pac_width - 1 downto 0);
  signal adc_data       : std_logic_vector(adc_width - 1 downto 0) := (others => '0');
  signal adc_data_valid : std_logic                                := '0';

  signal out_data_i     : std_logic_vector(out_width - 1 downto 0);
  signal out_data_q     : std_logic_vector(out_width - 1 downto 0);
  signal out_data_valid : std_logic;

  -- simulation signals
  signal counter : integer := 0;

  file stim_file   : text;
  file output_file : text;

  signal files_read : std_logic := '0';
  signal file_wrote : std_logic := '0';

  type type_results is array(0 to num_samples - 1) of signed(out_width - 1 downto 0);

  type in_data_type is array(0 to num_samples - 1) of std_logic_vector(adc_width - 1 downto 0);

  signal effective_results_i : type_results;
  signal effective_results_q : type_results;

  signal input_data_tdata : in_data_type;

begin

  iq_multiplier_inst : component iq_multiplier
    generic map (
      pac_width => pac_width,
      gen_width => gen_width,
      adc_width => adc_width,
      out_width => out_width
    )
    port map (
      clk            => clk,
      reset          => reset,
      run            => run,
      config_port    => config_port,
      init_freq      => std_logic_vector(init_freq),
      init_phase     => std_logic_vector(init_phase),
      adc_data       => adc_data,
      adc_data_valid => adc_data_valid,
      out_data_i     => out_data_i,
      out_data_q     => out_data_q,
      out_data_valid => out_data_valid
    );

  -- Clock process
  clk <= not clk after clk_period / 2;

  -- Stimulus processes
  stim_process : process is

    variable text_line : line;

    variable var_adc_data      : std_logic_vector(out_width - 1 downto 0);
    variable var_pac_width_len : std_logic_vector(pac_width - 1 downto 0);

  begin

    reset <= '1';
    wait for 10 * clk_period;

    if (files_read = '0') then
      file_open(stim_file, "stimuli.txt", read_mode);

      -- first we have the generator configuration
      readline(stim_file, text_line);

      read(text_line, var_pac_width_len);
      init_freq  <= unsigned(var_pac_width_len);
      read(text_line, var_pac_width_len);
      init_phase <= unsigned(var_pac_width_len);

      -- now we have num_samples * num_in_data lines of adc_data
      report "Read inputs";

      for i in 0 to num_samples - 1 loop

        readline(stim_file, text_line);

        read(text_line, var_adc_data);
        input_data_tdata(i) <= var_adc_data;

      end loop;

      file_close(stim_file);

      files_read <= '1';
    end if;

    reset       <= '0';
    wait for 10 * clk_period;
    config_port <= '1';
    wait for 10 * clk_period;
    config_port <= '0';

    wait for 10 * clk_period;

    run <= '1';
    run <= '0' after 2 * clk_period;

    wait for 9 * clk_period;

    for i in 0 to num_samples - 1 loop

      adc_data       <= input_data_tdata(i);
      adc_data_valid <= '1';
      wait for clk_period;

    end loop;

    wait for clk_period;

    adc_data_valid <= '0';

    wait;

  end process stim_process;

  check_results : process (clk) is

    variable result_line : line;

  begin

    if (rising_edge(clk) and files_read = '1') then
      if (out_data_valid = '1') then
        counter <= counter + 1;
      end if;
      if (counter < num_samples and out_data_valid = '1') then
        effective_results_i(counter) <= signed(out_data_i);
        effective_results_q(counter) <= signed(out_data_q);
      elsif (counter = num_samples and file_wrote = '0') then
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
