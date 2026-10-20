-- AXI-Stream gate / flusher.
--   run = '1' : transparent pass-through (tdata, tvalid, tready all unmodified,
--               so the AXI-Stream handshake is preserved: a beat is consumed
--               upstream only when the downstream accepts it).
--   run = '0' : the upstream FIFO is drained (tready = '1') and nothing is
--               forwarded (tvalid = '0'), used to clear the FIFOs.
-- It is purely combinational on purpose: a registered tready with an
-- unconditionally registered tdata/tvalid duplicates and loses beats whenever
-- the downstream (DMA) de-asserts tready.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dump is
  port (
    clk : in    std_logic;
    run : in    std_logic;

    s_axi_tdata  : in    std_logic_vector(255 downto 0);
    s_axi_tvalid : in    std_logic;
    s_axi_tready : out   std_logic;

    m_axi_tdata  : out   std_logic_vector(255 downto 0);
    m_axi_tvalid : out   std_logic;
    m_axi_tready : in    std_logic
  );
end entity dump;

architecture behav of dump is

begin

  m_axi_tdata  <= s_axi_tdata when run = '1' else (others => '0');
  m_axi_tvalid <= s_axi_tvalid and run;
  s_axi_tready <= m_axi_tready when run = '1' else '1';

end architecture behav;
