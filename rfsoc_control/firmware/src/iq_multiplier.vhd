library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity iq_multiplier is
  generic (
    pac_width : integer := 32;
    gen_width : integer := 18; -- used by dds

    adc_width : integer := 16; -- input width from the ADC
    out_width : integer := 16;

    out_delay : integer := 4 -- delay output valid for mult sync
  );
  port (
    clk         : in    std_logic;
    reset       : in    std_logic;
    run         : in    std_logic;
    config_port : in    std_logic;

    init_freq  : in    std_logic_vector(pac_width - 1 downto 0);
    init_phase : in    std_logic_vector(pac_width - 1 downto 0);

    -- data from the ADC
    adc_data       : in    std_logic_vector(adc_width - 1 downto 0);
    adc_data_valid : in    std_logic;
    -- output
    out_data_i     : out   std_logic_vector(out_width - 1 downto 0);
    out_data_q     : out   std_logic_vector(out_width - 1 downto 0);
    out_data_valid : out   std_logic;

    dds_output : out   std_logic_vector(adc_width - 1 downto 0);
    dds_valid  : out   std_logic
  );
end entity iq_multiplier;

architecture iq_multiplier_arch of iq_multiplier is

  component dds is
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

  component multiplier is
    generic (
      len_a   : integer := gen_width;
      len_b   : integer := adc_width;
      len_c   : integer := out_width;
      shift   : integer := 0;
      correct : integer := 0
    );
    port (
      clk   : in    std_logic;
      a     : in    std_logic_vector(len_a - 1 downto 0);
      b     : in    std_logic_vector(len_b - 1 downto 0);
      zlast : out   std_logic_vector(len_c - 1 downto 0)
    );
  end component multiplier;

  signal mult_i : std_logic_vector(out_width - 1 downto 0) := (others => '0');
  signal mult_q : std_logic_vector(out_width - 1 downto 0) := (others => '0');

  constant pi_half      : unsigned(pac_width - 1 downto 0) := (pac_width - 2 => '1', others => '0');
  signal   init_phase_q : unsigned(pac_width - 1 downto 0);

  signal i_data_output  : signed(gen_width - 1 downto 0);
  signal q_data_output  : signed(gen_width - 1 downto 0);
  signal i_output_valid : std_logic := '0';
  signal q_output_valid : std_logic := '0';

  type type_deayed is array(out_delay - 1 downto 0) of std_logic;

  signal out_delayed : type_deayed := (others => '0');

begin

  init_phase_q <= unsigned(init_phase) + pi_half;
  dds_output   <= std_logic_vector(i_data_output(gen_width - 1 downto gen_width - adc_width));
  dds_valid    <= i_output_valid;

  i_dds : component dds
    port map (
      clk          => clk,
      reset        => reset,
      run          => run,
      config_port  => config_port,
      init_freq    => unsigned(init_freq),
      init_phase   => unsigned(init_phase),
      data_output  => i_data_output,
      output_valid => i_output_valid
    );

  q_dds : component dds
    port map (
      clk          => clk,
      reset        => reset,
      run          => run,
      config_port  => config_port,
      init_freq    => unsigned(init_freq),
      init_phase   => init_phase_q,
      data_output  => q_data_output,
      output_valid => q_output_valid
    );

  multiplier_inst_i : component multiplier
    generic map (
      len_a   => gen_width,
      len_b   => adc_width,
      len_c   => out_width,
      shift   => 0,
      correct => 0
    )
    port map (
      clk   => clk,
      a     => std_logic_vector(i_data_output),
      b     => std_logic_vector(adc_data),
      zlast => mult_i
    );

  multiplier_inst_q : component multiplier
    generic map (
      len_a   => gen_width,
      len_b   => adc_width,
      len_c   => out_width,
      shift   => 0,
      correct => 0
    )
    port map (
      clk   => clk,
      a     => std_logic_vector(q_data_output),
      b     => std_logic_vector(adc_data),
      zlast => mult_q
    );

  proc : process (clk) is
  begin

    if rising_edge(clk) then
      out_data_i <= mult_i;
      out_data_q <= mult_q;

      out_delayed(0)                      <= i_output_valid and adc_data_valid;
      out_data_valid                      <= out_delayed(out_delay - 1);
      out_delayed(out_delay - 1 downto 1) <= out_delayed(out_delay - 2 downto 0);
    end if;

  end process proc;

end architecture iq_multiplier_arch;
