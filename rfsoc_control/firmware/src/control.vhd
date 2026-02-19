library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity control is
  port (
    clk_adc      : in    std_logic;
    control_port : in    std_logic_vector(2 downto 0);
    reset        : out   std_logic;
    resetn       : out   std_logic;
    config_port  : out   std_logic;
    run          : out   std_logic
  );
end entity control;

architecture behav of control is

  signal sync_control : std_logic_vector(2 downto 0) := (others => '0');
  signal sig_reset    : std_logic                    := '0';

begin

  sync : process (clk_adc) is
  begin

    if rising_edge(clk_adc) then
      sync_control <= control_port;
    end if;

  end process sync;

  reset  <= sig_reset;
  resetn <= '0' when sig_reset = '1' else
            '1';

  translate_ctrl : process (clk_adc) is
  begin

    if rising_edge(clk_adc) then
      if (sync_control(0) = '1') then
        sig_reset   <= '1';
        config_port <= '0';
        run         <= '0';
      elsif (sync_control(1) = '1') then
        sig_reset   <= '0';
        config_port <= '1';
        run         <= '0';
      elsif (sync_control(2) = '1') then
        sig_reset   <= '0';
        config_port <= '0';
        run         <= '1';
      else
        sig_reset   <= '0';
        config_port <= '0';
        run         <= '0';
      end if;
    end if;

  end process translate_ctrl;

end architecture behav;
