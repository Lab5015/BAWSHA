library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

-- multiplier must give round-half-to-even(a*b / 2^(len_a+len_b-len_c)):
-- exact match, no DC bias.

entity tb_multiplier is
end entity tb_multiplier;

architecture sim of tb_multiplier is

  constant len_a : integer := 18;
  constant len_b : integer := 16;
  constant len_c : integer := 16;
  constant cut   : integer := len_a + len_b - len_c;

  component multiplier is
    generic (
      len_a   : integer := 24;
      len_b   : integer := 16;
      len_c   : integer := 16;
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

  signal clk : std_logic                            := '0';
  signal a   : std_logic_vector(len_a - 1 downto 0) := (others => '0');
  signal b   : std_logic_vector(len_b - 1 downto 0) := (others => '0');
  signal z   : std_logic_vector(len_c - 1 downto 0);

begin

  clk <= not clk after 5 ns;

  dut : component multiplier
    generic map (
      len_a => len_a, len_b => len_b, len_c => len_c
    )
    port map (
      clk   => clk,
      a     => a,
      b     => b,
      zlast => z
    );

  stim : process is

    variable s1, s2           : positive := 7;
    variable r                : real;
    variable ia, ib           : integer;
    variable p, q, remd, expv : integer;
    variable sum_err          : real     := 0.0;
    variable bad              : integer  := 0;
    variable n                : integer  := 20000;

  begin

    for k in 0 to n - 1 loop

      if (k mod 50 = 0) then                                                         -- some exact ties (product multiple of 2^(cut-1))
        ia := (2 * ((k / 50) mod 4 - 2) + 1) * 2 ** (cut - 3);                       -- ia*4 = odd * 2^(cut-1)
        ib := 4;
      else
        uniform(s1, s2, r); ia := integer(round((r - 0.5) * 2.0 * 60000.0));
        uniform(s1, s2, r); ib := integer(round((r - 0.5) * 2.0 * 16000.0));
      end if;

      a <= std_logic_vector(to_signed(ia, len_a));
      b <= std_logic_vector(to_signed(ib, len_b));

      for t in 0 to 5 loop

        wait until rising_edge(clk);

      end loop;

      wait for 1 ns;
      p := ia * ib;
      q := p / 2 ** cut;                                                             -- truncates to zero; fix to floor

      if (p < 0 and (p mod 2 ** cut) /= 0) then
        q := q - 1;
      end if;

      remd := p - q * 2 ** cut;                                                      -- 0 .. 2^cut-1

      if (remd > 2 ** (cut - 1)) then
        expv := q + 1;
      elsif (remd < 2 ** (cut - 1)) then
        expv := q;
      elsif (q mod 2 = 0) then
        expv := q;
      else
        expv := q + 1;
      end if;

      if (to_integer(signed(z)) /= expv) then
        bad := bad + 1;
      end if;

      sum_err := sum_err + (real(to_integer(signed(z))) - real(p) / real(2 ** cut));

    end loop;

    report "mismatches " & integer'image(bad) & " of " & integer'image(n) &
           ", mean error [LSB] " & real'image(sum_err / real(n));
    assert bad = 0
      report "FAIL"
      severity failure;
    report "PASS";
    std.env.finish;

  end process stim;

end architecture sim;
