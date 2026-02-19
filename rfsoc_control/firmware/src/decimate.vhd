-- Implements a x5 decimation

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity decimate is
  generic (
    data_width : integer := 32;
    dec_width  : integer := 24
  );
  port (
    clk         : in    std_logic;
    reset       : in    std_logic;
    run         : in    std_logic;
    config_port : in    std_logic;
    dec_factor  : in    std_logic_vector(dec_width - 1 downto 0);
    data_in     : in    std_logic_vector(data_width - 1 downto 0);
    valid_in    : in    std_logic;
    data_out    : out   std_logic_vector(data_width - 1 downto 0);
    valid_out   : out   std_logic
  );
end entity decimate;

architecture behav of decimate is

  signal sig_valid_out : std_logic                                 := '0';
  signal sig_data_out  : std_logic_vector(data_width - 1 downto 0) := (others => '0');

  signal count      : unsigned(dec_width - 1 downto 0) := (others => '0');
  signal cur_factor : unsigned(dec_width - 1 downto 0) := (others => '0');

begin

  accumulate : process (clk) is
  begin

    if rising_edge(clk) then
      data_out  <= sig_data_out;
      valid_out <= sig_valid_out;
      if (reset = '1') then
        count         <= (others => '0');
        cur_factor    <= (others => '0');
        sig_valid_out <= '0';
      elsif (config_port = '1') then
        cur_factor <= unsigned(dec_factor) - 1;
        count      <= unsigned(dec_factor) - 1;
      elsif (run = '1') then
        sig_data_out <= data_in;
        if (valid_in = '1') then
          if (count = cur_factor) then
            count         <= (others => '0');
            sig_valid_out <= '1';
          else
            count         <= count + 1;
            sig_valid_out <= '0';
          end if;
        else
          sig_valid_out <= '0';
        end if;
      else
        sig_valid_out <= '0';
      end if;
    end if;

  end process accumulate;

end architecture behav;
