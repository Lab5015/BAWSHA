library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity interpolator is
  generic (
    cos_table_len : integer := 10;
    gen_width     : integer := 18;
    pac_width     : integer := 32;
    amp_max       : integer := 65520; -- 131041;

    delay : integer := 8
  );
  port (
    clk   : in    std_logic;
    reset : in    std_logic;

    phase : in    unsigned(gen_width + cos_table_len - 1 downto 0);

    data_output  : out   signed(gen_width - 1 downto 0);
    output_valid : out   std_logic
  );
end entity interpolator;

architecture interp_arch of interpolator is

  -- generate cos_table

  type rom_type is array (0 to 2 ** cos_table_len - 1) of signed(gen_width - 1 downto 0);

  impure function init_cos_table return rom_type is

    variable theta            : real;
    variable cos_value        : real;
    variable scaled_cos_value : integer;
    variable rom              : rom_type;

  begin

    for i in 0 to 2 ** cos_table_len - 1 loop

      theta            := real(i) * (2.0 * math_pi / real(2 ** cos_table_len));
      cos_value        := cos(theta);
      scaled_cos_value := integer(round(cos_value * real(AMP_MAX)));
      rom(i)           := to_signed(scaled_cos_value, gen_width);

    end loop;

    return rom;

  end function init_cos_table;

  constant cos_table : rom_type := init_cos_table;

  -- pipelined interpolation
  signal round_shift_res : std_logic_vector(gen_width - 1 downto 0) := (others => '0');
  signal address         : unsigned(cos_table_len - 1 downto 0);

  type arr_val_a is array (delay - 4 downto 0) of signed(gen_width - 1 downto 0);

  signal vec_a              : arr_val_a                                := (others => (others => '0'));
  signal val_b              : signed(gen_width - 1 downto 0)           := (others => '0');
  signal diff_phase         : std_logic_vector(gen_width - 1 downto 0) := (others => '0');
  signal delayed_diff_phase : std_logic_vector(gen_width - 1 downto 0) := (others => '0');
  signal vec_out_valid      : std_logic_vector(delay - 1 downto 0)     := (others => '0');

  signal data_output_0   : signed(gen_width - 1 downto 0) := (others => '0');
  signal sig_data_output : signed(gen_width - 1 downto 0) := (others => '0');

  component multiplier is
    generic (
      len_a   : integer := gen_width;
      len_b   : integer := gen_width + 1;
      len_c   : integer := gen_width;
      shift   : integer := pac_width - gen_width - cos_table_len;
      correct : integer := -1
    );
    port (
      clk   : in    std_logic;
      a     : in    std_logic_vector(gen_width - 1 downto 0);
      b     : in    std_logic_vector(gen_width downto 0);
      zlast : out   std_logic_vector(gen_width - 1 downto 0)
    );
  end component multiplier;

begin

  mult_inst : component multiplier
    generic map (
      len_a   => gen_width,
      len_b   => gen_width + 1,
      len_c   => gen_width,
      shift   => pac_width - gen_width - cos_table_len,
      correct => - 1
    )
    port map (
      clk   => clk,
      a     => std_logic_vector(val_b - vec_a(0)),
      b     => '0' & std_logic_vector(delayed_diff_phase),
      zlast => round_shift_res
    );

  interpolate : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        vec_out_valid <= (others => '0');
      else
        vec_out_valid(0)   <= '1';
        address            <= phase(phase'length-1 downto phase'length - cos_table_len);
        diff_phase         <= std_logic_vector(phase(phase'length - cos_table_len - 1 downto 0));
        vec_a(0)           <= cos_table(to_integer(address));
        val_b              <= cos_table(to_integer(address + 1));
        delayed_diff_phase <= diff_phase;
        data_output_0      <= vec_a(vec_a'length-1) + signed(round_shift_res);
        sig_data_output    <= data_output_0;

        -- update vec_a and vec_out_valid
        vec_out_valid(vec_out_valid'length - 1 downto 1) <= vec_out_valid(vec_out_valid'length-2 downto 0);
        vec_a(vec_a'length - 1 downto 1)                 <= vec_a(vec_a'length-2 downto 0);
      end if;
    end if;

  end process interpolate;

  data_output <= sig_data_output when vec_out_valid(vec_out_valid'length - 1) = '1' else
                 (others => '0');

  output_valid <= vec_out_valid(vec_out_valid'length-1);

end architecture interp_arch;
