library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity tb_avg12 is
end entity tb_avg12;

architecture sim of tb_avg12 is

  signal clk   : std_logic := '0';
  signal d     : std_logic_vector(191 downto 0) := (others => '0');
  signal v     : std_logic := '0';
  signal q     : std_logic_vector(15 downto 0);
  signal qv    : std_logic;
  signal done  : boolean := false;

  type int_arr is array (0 to 63) of integer;
  signal expected : int_arr := (others => 0);

begin

  clk <= not clk after 4 ns when not done else '0';

  dut : entity work.avg12 port map (clk, d, v, q, qv);

  stim : process is
    variable seed1, seed2 : positive := 7;
    variable r : real;
    variable sum : integer;
    variable x : integer;
    variable errors : integer := 0;
    variable n_out : integer := 0;
  begin
    -- 40 random words, each checked after the 4-cycle latency
    for n in 0 to 39 loop
      sum := 0;
      for i in 0 to 11 loop
        if n = 0 then x := 32767; elsif n = 1 then x := -32768; elsif n = 2 then x := 0;
        else uniform(seed1, seed2, r); x := integer(r * 65535.0) - 32768; end if;
        d(16 * i + 15 downto 16 * i) <= std_logic_vector(to_signed(x, 16));
        sum := sum + x;
      end loop;
      -- expected = round(sum * 5461 / 65536) (floor(x + 0.5))
      expected(n mod 64) <= integer(floor(real(sum * 5461 + 32768) / 65536.0));
      v <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      if n >= 4 then
        null;
      end if;
    end loop;
    v <= '0';
    wait for 100 ns;
    done <= true;
    wait;
  end process stim;

  -- Checker: output at cycle k+4 corresponds to input k
  check : process (clk) is
    variable cnt : integer := 0;
    variable errors : integer := 0;
    variable pipe : int_arr := (others => 0);
    variable idx : integer := 0;
  begin
    if rising_edge(clk) then
      if qv = '1' then
        if to_integer(signed(q)) /= expected(cnt mod 64) then
          report "MISMATCH n=" & integer'image(cnt) & " got " & integer'image(to_integer(signed(q))) &
                 " exp " & integer'image(expected(cnt mod 64)) severity error;
          errors := errors + 1;
        end if;
        cnt := cnt + 1;
        if cnt = 40 then
          report "avg12 outputs checked: " & integer'image(cnt) & " errors: " & integer'image(errors);
        end if;
      end if;
    end if;
  end process check;

end architecture sim;
