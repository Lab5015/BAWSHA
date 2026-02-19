library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dump is
  port (
    clk : in    std_logic;
    run : in    std_logic;

    s_axi_tdata  : in    std_logic_vector(31 downto 0);
    s_axi_tlast  : in    std_logic;
    s_axi_tvalid : in    std_logic;
    s_axi_tready : out   std_logic;

    m_axi_tdata  : out   std_logic_vector(31 downto 0);
    m_axi_tlast  : out   std_logic;
    m_axi_tvalid : out   std_logic;
    m_axi_tready : in    std_logic
  );
end entity dump;

architecture behav of dump is

begin

  split : process (clk) is
  begin

    if rising_edge(clk) then
      if (run = '1') then
        m_axi_tdata  <= s_axi_tdata;
        m_axi_tlast  <= s_axi_tlast;
        m_axi_tvalid <= s_axi_tvalid;
        s_axi_tready <= m_axi_tready;
      else
        s_axi_tready <= '1';
        m_axi_tvalid <= '0';
        m_axi_tdata  <= (others => '0');
        m_axi_tlast  <= '0';
      end if;
    end if;

  end process split;

end architecture behav;
