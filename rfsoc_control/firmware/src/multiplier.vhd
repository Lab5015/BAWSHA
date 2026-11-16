library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity multiplier is
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
end entity multiplier;

architecture arch of multiplier is

  signal ar : signed(a'range)                          := (others => '0');
  signal br : signed(b'range)                          := (others => '0');
  signal z1 : signed(a'length + b'length - 1 downto 0) := (others => '0');

  signal multaddr       : signed(a'length + b'length + shift + correct - 1 downto 0) := (others => '0');
  signal multadd        : signed(a'length + b'length - 1 downto 0)                   := (others => '0');
  signal pattern_detect : boolean                                                    := False;

  signal sig_zlast : std_logic_vector(len_c - 1 downto 0) := (others => '0');

  -- number of product bits dropped by the output cut
  constant cut     : integer                            := len_a + len_b - len_c;
  constant pattern : signed(cut - 1 downto 0)           := (others => '0');
  constant c       : signed(len_a + len_b - 1 downto 0) := shift_left(to_signed(1, len_a + len_b), cut - 1) - 1;

begin

  multadd <= z1 + c + 1;
  zlast   <= sig_zlast;

  detect_pattern : process (clk) is
  begin

    if rising_edge(clk) then
      ar <= signed(a);
      br <= signed(b);
      z1 <= ar * br;

      multaddr <= resize(multadd, multaddr'length) sla shift;
      if (multadd(cut - 1 downto 0) = pattern) then
        pattern_detect <= true;
      else
        pattern_detect <= false;
      end if;
    end if;

  end process detect_pattern;

  round : process (clk) is
  begin

    if rising_edge(clk) then
      if (pattern_detect = true) then
        sig_zlast <= std_logic_vector(multaddr(multaddr'length - 1 downto multaddr'length - len_c + 1)) & "0";
      else
        sig_zlast <= std_logic_vector(multaddr(multaddr'length - 1 downto multaddr'length - len_c));
      end if;
    end if;

  end process round;

end architecture arch;
