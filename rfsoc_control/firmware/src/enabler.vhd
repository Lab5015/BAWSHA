library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity enabler is
  port (
    clk      : in    std_logic;
    s0_data  : in    std_logic_vector(31 downto 0);
    s0_valid : in    std_logic;
    s1_data  : in    std_logic_vector(31 downto 0);
    s1_valid : in    std_logic;
    active   : in    std_logic;
    m_data   : out   std_logic_vector(31 downto 0);
    m_valid  : out   std_logic
  );
end entity enabler;

architecture rtl of enabler is

begin

  sync_r : process (clk) is
  begin

    if rising_edge(clk) then
      if (active = '1') then
        m_data  <= s0_data;
        m_valid <= s0_valid;
      else
        m_data  <= s1_data;
        m_valid <= s1_valid;
      end if;
    end if;

  end process sync_r;

end architecture rtl;
