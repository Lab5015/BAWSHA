library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity counter_mod is
  port (
    clk          : in    std_logic;
    reset        : in    std_logic;
    in_1         : in    std_logic;
    in_2         : in    std_logic;
    counter_port : out   std_logic_vector(31 downto 0)
  );
end entity counter_mod;

architecture behav of counter_mod is

  signal sync_counter : unsigned(31 downto 0) := (others => '0');

begin

  counter_port <= std_logic_vector(sync_counter);

  count : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        sync_counter <= (others => '0');
      else
        if (in_1 = '1' or in_2 = '1') then
          sync_counter <= sync_counter + 1;
        end if;
      end if;
    end if;

  end process count;

end architecture behav;
