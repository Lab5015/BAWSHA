
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use ieee.std_logic_textio.all;

entity tb_decimate is
  generic (
    data_width : integer := 32;
    dec_width  : integer := 24;
    clk_period : time    := 5 ns;

    num_samples : integer := 10_000;
    num_results : integer := 100
  );
end entity tb_decimate;

architecture behaviour of tb_decimate is

  component decimate is
    generic (
      data_width : integer := data_width;
      dec_width  : integer := dec_width
    );
    port (
      clk         : in    std_logic;
      reset       : in    std_logic;
      run         : in    std_logic;
      config_port : in    std_logic;
      dec_factor  : in    std_logic_vector(dec_width - 1 downto 0);
      data_in     : in    std_logic_vector(data_width - 1 downto 0);
      valid_in    : in    std_logic;
      data_out    : out   std_logic_vector(data_width - 1 downto 0);
      valid_out   : out   std_logic
    );
  end component decimate;

  signal clk    : std_logic := '0';
  signal reset  : std_logic := '0';
  signal run    : std_logic := '1';
  signal config : std_logic := '0';

  signal dec_factor : std_logic_vector(dec_width - 1 downto 0);
  signal data_in    : std_logic_vector(data_width - 1 downto 0);
  signal valid_in   : std_logic := '0';
  signal data_out   : std_logic_vector(data_width - 1 downto 0);
  signal valid_out  : std_logic;

  file   stim_file   : text;
  file   output_file : text;
  signal files_read  : std_logic := '0';
  signal file_wrote  : std_logic := '0';

  type type_results is array(0 to num_results - 1) of std_logic_vector(data_width - 1 downto 0);

  signal effective_results : type_results;

  signal counter : integer := 0;

begin

  dut : component decimate
    generic map (
      data_width => data_width
    )
    port map (
      clk         => clk,
      reset       => reset,
      run         => run,
      config_port => config,
      dec_factor  => dec_factor,
      data_in     => data_in,
      valid_in    => valid_in,
      data_out    => data_out,
      valid_out   => valid_out
    );

  -- Clock process
  clk <= not clk after clk_period / 2;

  -- Stimulus process
  stim_process : process is

    variable text_line : line;
    variable var_dec   : std_logic_vector(dec_width - 1 downto 0);
    variable var_data  : std_logic_vector(data_width - 1 downto 0);

  begin

    -- Reset the system
    reset <= '1';
    wait for 10 * clk_period;
    reset <= '0';

    if (files_read = '0') then
      files_read <= '1';
      file_open(stim_file, "stimuli.txt", read_mode);

      readline(stim_file, text_line);

      read(text_line, var_dec);
      dec_factor <= var_dec;

      config <= '1';
      wait for 10 * clk_period;
      config <= '0';

      for i in 0 to num_samples - 1 loop

        readline(stim_file, text_line);

        read(text_line, var_data);
        data_in  <= var_data;
        valid_in <= '1';
        wait for clk_period;

      end loop;

      file_close(stim_file);
    end if;

    valid_in <= '0';

    wait;

  end process stim_process;

  check_results : process (clk) is

    variable result_line : line;

  begin

    if rising_edge(clk) then
      if (counter <= num_results) then
        if (valid_out = '1' and counter < num_results) then
          effective_results(counter) <= data_out;
          counter                    <= counter + 1;
        end if;
        if (counter = num_results and file_wrote = '0') then
          file_open(output_file, "effective_results.txt", write_mode);

          for i in effective_results'range loop

            write(result_line, integer'image(to_integer(signed(effective_results(i)))));
            writeline(output_file, result_line);

          end loop;

          file_close(output_file);
          report "Output file written";
          file_wrote <= '1';
        end if;
      end if;
    end if;

  end process check_results;

end architecture behaviour;
