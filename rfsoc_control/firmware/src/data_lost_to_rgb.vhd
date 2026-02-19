library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity data_lost_to_rgb is
  port (
    data_0  : in    std_logic_vector(31 downto 0);
    data_1  : in    std_logic_vector(31 downto 0);
    data_2  : in    std_logic_vector(31 downto 0);
    data_3  : in    std_logic_vector(31 downto 0);
    data_4  : in    std_logic_vector(31 downto 0);
    data_5  : in    std_logic_vector(31 downto 0);
    data_6  : in    std_logic_vector(31 downto 0);
    data_7  : in    std_logic_vector(31 downto 0);
    data_8  : in    std_logic_vector(31 downto 0);
    data_9  : in    std_logic_vector(31 downto 0);
    data_10 : in    std_logic_vector(31 downto 0);
    data_11 : in    std_logic_vector(31 downto 0);
    data_12 : in    std_logic_vector(31 downto 0);
    data_13 : in    std_logic_vector(31 downto 0);
    data_14 : in    std_logic_vector(31 downto 0);
    data_15 : in    std_logic_vector(31 downto 0);
    led_r   : out   std_logic;
    led_g   : out   std_logic;
    led_b   : out   std_logic
  );
end entity data_lost_to_rgb;

architecture rtl of data_lost_to_rgb is

  constant zero : std_logic_vector(31 downto 0) := (others => '0');

  signal data_lost : std_logic := '0';

begin

  data_lost <= '1' when data_0 /= zero else
               '1' when data_1 /= zero else
               '1' when data_2 /= zero else
               '1' when data_3 /= zero else
               '1' when data_4 /= zero else
               '1' when data_5 /= zero else
               '1' when data_6 /= zero else
               '1' when data_7 /= zero else
               '1' when data_8 /= zero else
               '1' when data_9 /= zero else
               '1' when data_10 /= zero else
               '1' when data_11 /= zero else
               '1' when data_12 /= zero else
               '1' when data_13 /= zero else
               '1' when data_14 /= zero else
               '1' when data_15 /= zero else
               '0';
  led_r     <= data_lost;
  led_b     <= '0';
  led_g     <= not data_lost;

end architecture rtl;
