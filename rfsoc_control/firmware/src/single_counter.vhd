library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sing_counter_mod is
  port (
    clk : in    std_logic;
    run : in    std_logic;
    rst : in    std_logic;

    s_axis_tdata  : in    std_logic_vector(31 downto 0);
    s_axis_tlast  : in    std_logic;
    s_axis_tvalid : in    std_logic;
    s_axis_tready : out   std_logic;

    m_axis_tdata  : out   std_logic_vector(31 downto 0);
    m_axis_tlast  : out   std_logic;
    m_axis_tvalid : out   std_logic;
    m_axis_tready : in    std_logic;

    dropped : in    std_logic;

    counter_port : out   std_logic_vector(63 downto 0)
  );
end entity sing_counter_mod;

architecture behav of sing_counter_mod is

  signal internal_counter : unsigned(63 downto 0) := (others => '0');
  signal internal_tlast   : std_logic             := '0';

begin

  pass : process (clk) is
  begin

    if rising_edge(clk) then
      m_axis_tdata  <= s_axis_tdata;
      m_axis_tlast  <= s_axis_tlast;
      m_axis_tvalid <= s_axis_tvalid;
      s_axis_tready <= m_axis_tready;
    end if;

  end process pass;

  count : process (clk) is
  begin

    if rising_edge(clk) then
      if (rst = '1') then
        internal_counter <= (others => '0');
      elsif (run = '1') then
        internal_counter <= internal_counter + 1;
      end if;
    end if;

  end process count;

  save_count_tlast : process (clk) is
  begin

    if rising_edge(clk) then
      if (s_axis_tlast <= '1' and s_axis_tvalid = '1' and m_axis_tready = '1') then
        internal_tlast <= '1';
      end if;
      if (internal_tlast = '1') then
        counter_port   <= std_logic_vector(internal_counter);
        internal_tlast <= '0';
      end if;
    end if;

  end process save_count_tlast;

end architecture behav;
