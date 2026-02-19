library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tlast_gen is
  generic (
    packets_width : integer := 10
  );
  port (
    clk    : in    std_logic;
    reset  : in    std_logic;
    resetn : in    std_logic;

    out_ready : in    std_logic;

    in_data_i : in    std_logic_vector(31 downto 0);
    in_data_q : in    std_logic_vector(31 downto 0);
    in_valid  : in    std_logic;

    out_data_i : out   std_logic_vector(31 downto 0);
    out_data_q : out   std_logic_vector(31 downto 0);
    out_tlast  : out   std_logic;
    out_valid  : out   std_logic;

    data_lost_port : out   std_logic_vector(31 downto 0)
  );
end entity tlast_gen;

architecture rtl of tlast_gen is

  signal packet_count  : unsigned(packets_width - 1 downto 0) := (others => '0');
  signal num_tlast_reg : unsigned(packets_width - 1 downto 0) := to_unsigned(255, packets_width);
  signal data_lost     : unsigned(31 downto 0)                := (others => '0');

begin

  sync_r : process (clk) is
  begin

    if rising_edge(clk) then
      out_valid  <= in_valid;
      out_data_i <= in_data_i;
      out_data_q <= in_data_q;

      if (reset = '1' or resetn = '0') then
        packet_count <= (others => '0');
        out_tlast    <= '0';
        data_lost    <= (others => '0');
      else
        if (in_valid = '1' and out_ready = '1') then
          if (packet_count = num_tlast_reg) then
            out_tlast    <= '1';
            packet_count <= (others => '0');
          else
            out_tlast    <= '0';
            packet_count <= packet_count + 1;
          end if;
        elsif (in_valid = '1') then
          data_lost <= data_lost + 1;
        else
          out_tlast <= '0';
        end if;
      end if;
    end if;

  end process sync_r;

  data_lost_port <= std_logic_vector(data_lost);

end architecture rtl;
