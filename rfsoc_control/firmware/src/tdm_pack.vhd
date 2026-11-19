-- TDM AXI-Stream -> parallel word packer, the inverse of tdm_interleave.
--
-- Beat k of a burst goes into slot k (bits (k+1)*width-1 downto k*width) of
-- out_data. The burst must end with tlast on slot n_ch-1, then the word is
-- published (out_data updated, out_valid pulsed for one cycle). out_data holds
-- its value until the next complete word.
--
-- Framing errors (tlast before slot n_ch-1, or slot n_ch-1 without tlast) set
-- sync_error (sticky until reset), discard the partial word and restart at
-- slot 0. Restarting on tlast resynchronises the packer to the source framing.
-- There is no tready: the source (FIR Compiler) cannot be stalled.
--
-- Resources: 2*n_ch*width (accumulator + output) + ~log2(n_ch) + 2 flip-flops.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tdm_pack is
  generic (
    n_ch  : integer := 8;
    width : integer := 32
  );
  port (
    clk           : in    std_logic;
    reset         : in    std_logic;
    s_axis_tdata  : in    std_logic_vector(width - 1 downto 0);
    s_axis_tvalid : in    std_logic;
    s_axis_tlast  : in    std_logic;
    out_data      : out   std_logic_vector(n_ch * width - 1 downto 0);
    out_valid     : out   std_logic;
    sync_error    : out   std_logic
  );
end entity tdm_pack;

architecture behav of tdm_pack is

  -- beats enter at the top and shift down, so after n_ch beats slot 0 is at
  -- the bottom: no per-slot write decoder is needed
  signal acc     : std_logic_vector(n_ch * width - 1 downto 0) := (others => '0');
  signal word    : std_logic_vector(n_ch * width - 1 downto 0) := (others => '0');
  signal idx     : integer range 0 to n_ch - 1                 := 0;
  signal sig_vld : std_logic                                   := '0';
  signal sig_err : std_logic                                   := '0';

begin

  pack : process (clk) is
  begin

    if rising_edge(clk) then
      sig_vld <= '0';
      if (reset = '1') then
        idx     <= 0;
        sig_err <= '0';
      elsif (s_axis_tvalid = '1') then
        if (idx = n_ch - 1) then
          if (s_axis_tlast = '1') then
            word    <= s_axis_tdata & acc(n_ch * width - 1 downto width);
            sig_vld <= '1';
          else
            sig_err <= '1';
          end if;
          idx <= 0;
        elsif (s_axis_tlast = '1') then
          sig_err <= '1';
          idx     <= 0;
        else
          acc <= s_axis_tdata & acc(n_ch * width - 1 downto width);
          idx <= idx + 1;
        end if;
      end if;
    end if;

  end process pack;

  out_data   <= word;
  out_valid  <= sig_vld;
  sync_error <= sig_err;

end architecture behav;
