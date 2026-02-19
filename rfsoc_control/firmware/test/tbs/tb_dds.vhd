library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use ieee.std_logic_textio.all;

entity tb_dds_chirp is
  generic (
    pac_width     : integer := 32;
    cos_table_len : integer := 10;
    gen_width     : integer := 18;
    clk_period    : time    := 10 ns;

    num_samples : integer := 10_000
  );
end entity tb_dds_chirp;

architecture behaviour of tb_dds_chirp is

  component dds is
    generic (
      pac_width       : integer := 32;
      cos_table_len   : integer := 10;
      gen_width       : integer := 18;
      delay_out_valid : integer := 5
    );
    port (
      clk         : in    std_logic;
      reset       : in    std_logic;
      run         : in    std_logic;
      config_port : in    std_logic;

      init_freq  : in    unsigned(pac_width - 1 downto 0);
      init_phase : in    unsigned(pac_width - 1 downto 0);

      data_output  : out   signed(gen_width - 1 downto 0);
      output_valid : out   std_logic
    );
  end component dds;

  signal clk         : std_logic := '0';
  signal reset       : std_logic;
  signal config_port : std_logic;
  signal run         : std_logic := '0';

  signal init_freq  : unsigned(pac_width - 1 downto 0);
  signal init_phase : unsigned(pac_width - 1 downto 0);

  signal dds_output   : signed(gen_width - 1 downto 0);
  signal output_valid : std_logic;

  file   stim_file   : text;
  file   output_file : text;
  signal files_read  : std_logic := '0';
  signal file_wrote  : std_logic := '0';

  type type_results is array(0 to num_samples - 1) of signed(gen_width - 1 downto 0);

  signal effective_results : type_results;

  signal counter : integer := 0;

begin

  dds_inst : component dds
    generic map (
      pac_width       => pac_width,
      cos_table_len   => cos_table_len,
      gen_width       => gen_width,
      delay_out_valid => 8
    )
    port map (
      clk          => clk,
      reset        => reset,
      run          => run,
      config_port  => config_port,
      init_freq    => init_freq,
      init_phase   => init_phase,
      data_output  => dds_output,
      output_valid => output_valid
    );

  -- Clock process
  clk <= not clk after clk_period / 2;

  -- Stimulus process
  stim_process : process is

    variable text_line         : line;
    variable var_pac_width_len : std_logic_vector(pac_width - 1 downto 0);

  begin

    -- Reset the system
    reset <= '1';
    wait for 10 * clk_period;

    if (files_read = '0') then
      files_read <= '1';
      file_open(stim_file, "stimuli.txt", read_mode);
      -- read DAC A parameters
      readline(stim_file, text_line);

      read(text_line, var_pac_width_len);
      init_freq  <= unsigned(var_pac_width_len);
      read(text_line, var_pac_width_len);
      init_phase <= unsigned(var_pac_width_len);

      file_close(stim_file);
    end if;

    reset       <= '0';
    wait for 10 * clk_period;
    config_port <= '1';
    wait for 10 * clk_period;
    config_port <= '0';

    wait for 10 * clk_period;

    run <= '1';
    run <= '0' after 2 * clk_period;

    wait;

  end process stim_process;

  check_results : process (clk) is

    variable result_line : line;

  begin

    if rising_edge(clk) then
      if (counter <= num_samples) then
        if (output_valid = '1' and counter < num_samples) then
          effective_results(counter) <= signed(dds_output);
          counter                    <= counter + 1;
        end if;
        if (counter = num_samples and file_wrote = '0') then
          file_open(output_file, "effective_results.txt", write_mode);            -- Open the output file

          for i in effective_results'range loop

            write(result_line, integer'image(to_integer(effective_results(i))));
            writeline(output_file, result_line);                                  -- Write the line to the file

          end loop;

          file_close(output_file);                                                -- Close the file after writing
          report "Output file written";
          file_wrote <= '1';
        end if;
      end if;
    end if;

  end process check_results;

end architecture behaviour;
