library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dds is
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
end entity dds;

architecture dds_arch of dds is

  component interpolator is
    generic (
      cos_table_len : integer := cos_table_len;
      gen_width     : integer := gen_width;
      pac_width     : integer := pac_width
    );
    port (
      clk   : in    std_logic;
      reset : in    std_logic;

      phase : in    unsigned(gen_width + cos_table_len - 1 downto 0);

      data_output  : out   signed(gen_width - 1 downto 0);
      output_valid : out   std_logic
    );
  end component interpolator;

  type state is (idle, synthesis);

  signal current_state : state := idle;

  signal sig_phase : unsigned(pac_width - 1 downto 0) := (others => '0');
  signal sig_freq  : unsigned(pac_width - 1 downto 0) := (others => '0');

  signal delayed_out_valid : std_logic_vector(delay_out_valid - 1 downto 0) := (others => '0');
  signal sig_output_valid  : std_logic                                      := '0';

begin

  output_valid <= sig_output_valid;

  interpolator_sin : component interpolator
    generic map (
      cos_table_len => cos_table_len,
      gen_width     => gen_width,
      pac_width     => pac_width
    )
    port map (
      clk          => clk,
      reset        => reset,
      phase        => sig_phase(pac_width - 1 downto pac_width - cos_table_len - gen_width),
      data_output  => data_output,
      output_valid => delayed_out_valid(0)
    );

  dds : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        sig_phase                                       <= (others => '0');
        sig_freq                                        <= (others => '0');
        sig_output_valid                                <= '0';
        current_state                                   <= idle;
        delayed_out_valid(delay_out_valid - 1 downto 1) <= (others => '0');
      else

        case current_state is

          when idle =>

            if (config_port = '1') then
              sig_phase <= init_phase;
              sig_freq  <= init_freq;
            elsif (run = '1') then
              current_state <= synthesis;
            end if;

          when synthesis =>

            delayed_out_valid(delay_out_valid - 1 downto 1) <= delayed_out_valid(delay_out_valid - 2 downto 0);
            sig_output_valid                                <= delayed_out_valid(delay_out_valid - 1);
            sig_phase                                       <= sig_phase + sig_freq;

        end case;

      end if;
    end if;

  end process dds;

end architecture dds_arch;
