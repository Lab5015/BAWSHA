-- Parallel -> TDM AXI-Stream serializer for the shared (multi-channel) FIR chain.
--
-- On in_valid all n_ch channels are captured into a shift register and then
-- sent as n_ch beats, channel 0 first, with tlast on channel n_ch-1 (FIR
-- Compiler vector framing). The output is registered and follows the AXI-Stream
-- rules: a beat transfers when tvalid = tready = '1', and tdata/tlast are held
-- while tvalid = '1' and tready = '0'.
--
-- Overflow policy: if in_valid arrives while a burst is still being sent, the
-- NEW sample set is dropped and overflow is set (sticky until reset), so the
-- burst in flight is never broken and the channel order downstream never slips.
-- An in_valid in the same cycle in which the last beat transfers is accepted
-- (the buffer is free on that edge), so back-to-back bursts lose nothing.
--
-- Requires n_ch >= 2.
-- Resources: n_ch*width (shift register) + ~log2(n_ch) + 3 flip-flops.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tdm_interleave is
  generic (
    n_ch  : integer := 8;
    width : integer := 24
  );
  port (
    clk           : in    std_logic;
    reset         : in    std_logic;
    in_data       : in    std_logic_vector(n_ch * width - 1 downto 0);
    in_valid      : in    std_logic;
    m_axis_tdata  : out   std_logic_vector(width - 1 downto 0);
    m_axis_tvalid : out   std_logic;
    m_axis_tlast  : out   std_logic;
    m_axis_tready : in    std_logic;
    overflow      : out   std_logic
  );
end entity tdm_interleave;

architecture behav of tdm_interleave is

  signal shreg   : std_logic_vector(n_ch * width - 1 downto 0) := (others => '0');
  signal busy    : std_logic                                   := '0';
  signal last    : std_logic                                   := '0';
  signal idx     : integer range 0 to n_ch - 1                 := 0;
  signal sig_ovf : std_logic                                   := '0';

begin

  serialize : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        busy    <= '0';
        last    <= '0';
        idx     <= 0;
        sig_ovf <= '0';
      elsif (busy = '1') then
        if (m_axis_tready = '1') then
          if (idx = n_ch - 1) then
            -- last beat transfers now: the buffer is free on this edge
            if (in_valid = '1') then
              shreg <= in_data;
              idx   <= 0;
              last  <= '0';
            else
              busy <= '0';
              last <= '0';
            end if;
          else
            shreg <= std_logic_vector(shift_right(unsigned(shreg), width));
            idx   <= idx + 1;
            if (idx = n_ch - 2) then
              last <= '1';
            else
              last <= '0';
            end if;
            if (in_valid = '1') then
              sig_ovf <= '1';
            end if;
          end if;
        elsif (in_valid = '1') then
          sig_ovf <= '1';
        end if;
      elsif (in_valid = '1') then
        shreg <= in_data;
        busy  <= '1';
        idx   <= 0;
        last  <= '0';
      end if;
    end if;

  end process serialize;

  m_axis_tdata  <= shreg(width - 1 downto 0);
  m_axis_tvalid <= busy;
  m_axis_tlast  <= last;
  overflow      <= sig_ovf;

end architecture behav;
