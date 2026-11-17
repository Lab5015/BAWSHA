library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

-- Source -> dump -> sink with random sink back-pressure. The sink must see
-- the counter 0,1,2,... with no duplicates and no losses; with run = '0' the
-- source must be drained and nothing forwarded.
entity tb_dump is
end entity tb_dump;

architecture sim of tb_dump is

  signal clk  : std_logic := '0';
  signal run  : std_logic := '1';
  signal s_d, m_d : std_logic_vector(255 downto 0);
  signal s_v, s_r, m_v, m_r : std_logic;
  signal cnt  : unsigned(31 downto 0) := (others => '0');
  signal done : boolean := false;

begin

  clk <= not clk after 4 ns when not done else '0';

  dut : entity work.dump port map (clk, run, s_d, s_v, s_r, m_d, m_v, m_r);

  s_d <= std_logic_vector(resize(cnt, 256));
  s_v <= '1';

  process (clk) is
    variable seed1, seed2 : positive := 3;
    variable r : real;
    variable expect : unsigned(31 downto 0) := (others => '0');
    variable errors, got : integer := 0;
    variable cycles : integer := 0;
  begin
    if rising_edge(clk) then
      cycles := cycles + 1;
      if s_v = '1' and s_r = '1' then cnt <= cnt + 1; end if;
      if m_v = '1' and m_r = '1' then
        if unsigned(m_d(31 downto 0)) /= expect then
          errors := errors + 1;
          if errors < 5 then report "BAD beat, got " & integer'image(to_integer(unsigned(m_d(30 downto 0)))) & " exp " & integer'image(to_integer(expect)) severity error; end if;
          expect := unsigned(m_d(31 downto 0)) + 1;
        else
          expect := expect + 1;
        end if;
        got := got + 1;
      end if;
      if cycles = 3000 then run <= '0'; end if;
      if cycles > 3000 and m_v = '1' then errors := errors + 1; report "tvalid while run=0" severity error; end if;
      if cycles = 3200 then
        report "dump: beats=" & integer'image(got) & " errors=" & integer'image(errors) & " src_count=" & integer'image(to_integer(cnt));
        done <= true;
      end if;
      uniform(seed1, seed2, r);
      if r < 0.5 then m_r <= '1'; else m_r <= '0'; end if;
    end if;
  end process;

end architecture sim;
