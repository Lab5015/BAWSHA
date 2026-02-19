library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity splitter is
  port (
    active_port : in    std_logic_vector(31 downto 0);
    active_0    : out   std_logic;
    active_1    : out   std_logic;
    active_2    : out   std_logic;
    active_3    : out   std_logic;
    active_4    : out   std_logic;
    active_5    : out   std_logic;
    active_6    : out   std_logic;
    active_7    : out   std_logic;
    active_8    : out   std_logic;
    active_9    : out   std_logic;
    active_10   : out   std_logic;
    active_11   : out   std_logic;
    active_12   : out   std_logic;
    active_13   : out   std_logic;
    active_14   : out   std_logic;
    active_15   : out   std_logic
  );
end entity splitter;

architecture rtl of splitter is

begin

  active_0  <= active_port(0);
  active_1  <= active_port(1);
  active_2  <= active_port(2);
  active_3  <= active_port(3);
  active_4  <= active_port(4);
  active_5  <= active_port(5);
  active_6  <= active_port(6);
  active_7  <= active_port(7);
  active_8  <= active_port(8);
  active_9  <= active_port(9);
  active_10 <= active_port(10);
  active_11 <= active_port(11);
  active_12 <= active_port(12);
  active_13 <= active_port(13);
  active_14 <= active_port(14);
  active_15 <= active_port(15);

end architecture rtl;
