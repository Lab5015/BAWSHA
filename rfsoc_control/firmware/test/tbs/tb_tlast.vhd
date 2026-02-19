library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity tlast_gen_tb is
end entity tlast_gen_tb;

architecture tb of tlast_gen_tb is

  constant clk_period  : time      := 10 ns;
  signal   clk         : std_logic := '0';
  signal   reset       : std_logic := '0';
  signal   config_port : std_logic := '0';
  signal   run         : std_logic := '0';
  signal   full        : std_logic := '0';

  signal num_tlast : std_logic_vector(31 downto 0) := (others => '0');
  signal in_data_i : std_logic_vector(31 downto 0) := (others => '0');
  signal in_data_q : std_logic_vector(31 downto 0) := (others => '0');
  signal in_valid  : std_logic                     := '0';

  signal out_data_i     : std_logic_vector(31 downto 0);
  signal out_data_q     : std_logic_vector(31 downto 0);
  signal out_tlast      : std_logic;
  signal out_valid      : std_logic;
  signal data_lost_port : std_logic_vector(31 downto 0);

  component tlast_gen is
    generic (
      packets_width : integer := 10
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

begin

  -- Instantiate DUT
  uut : component tlast_gen
    generic map (
      packets_width => 10
    )
    port map (
      clk            => clk,
      reset          => reset,
      config_port    => config_port,
      run            => run,
      full           => full,
      num_tlast      => num_tlast,
      in_data_i      => in_data_i,
      in_data_q      => in_data_q,
      in_valid       => in_valid,
      out_data_i     => out_data_i,
      out_data_q     => out_data_q,
      out_tlast      => out_tlast,
      out_valid      => out_valid,
      data_lost_port => data_lost_port
    );

  -- Clock process
  clk_process : process is
  begin

    while true loop

      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;

    end loop;

  end process clk_process;

  -- Stimulus process
  stim_proc : process is
  begin

    -- Reset
    reset <= '1';
    wait for 3 * clk_period;
    reset <= '0';

    -- Configure
    config_port <= '1';
    num_tlast   <= std_logic_vector(to_unsigned(5, 32));
    wait for clk_period;
    config_port <= '0';

    -- Run sequence
    run <= '1';

    for i in 0 to 20 loop

      in_data_i <= std_logic_vector(to_unsigned(i, 32));
      in_data_q <= std_logic_vector(to_unsigned(i * 2, 32));
      in_valid  <= '1';
      wait for clk_period;

    end loop;

    -- Stop stimulus
    in_valid <= '0';
    wait for 10 * clk_period;

    -- End simulation
    report "Simulation finished.";
    wait;

  end process stim_proc;

end architecture tb;
