library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

-- tdm_interleave with random sink back-pressure.
-- Phase 1: in_valid every 30 cycles, tready low 40%: every captured set must
--          come out as one complete burst, in order, with no losses and
--          overflow = '0'.
-- Phase 2: in_valid every 5 cycles, tready low 75%: overflow must go '1', some
--          sets are dropped, but every delivered burst must equal one input
--          set (in increasing order) with tlast only on channel n_ch-1.
-- Phase 3: reset in the middle of a burst: tvalid and overflow go '0', the
--          partial burst is abandoned and later bursts are again lossless.
-- The monitor also checks AXI-Stream stability (tdata/tlast held while
-- tvalid = '1' and tready = '0').
entity tb_tdm_interleave is
end entity tb_tdm_interleave;

architecture sim of tb_tdm_interleave is

  constant n_ch  : integer := 8;
  constant width : integer := 24;
  constant n_p1  : integer := 400;
  constant n_p2  : integer := 600;
  constant n_p3  : integer := 100;
  constant max_s : integer := n_p1 + n_p2 + n_p3 + 8;

  type set_arr is array (0 to max_s - 1) of std_logic_vector(n_ch * width - 1 downto 0);

  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal in_data  : std_logic_vector(n_ch * width - 1 downto 0) := (others => '0');
  signal in_valid : std_logic := '0';
  signal tdata    : std_logic_vector(width - 1 downto 0);
  signal tvalid   : std_logic;
  signal tlast    : std_logic;
  signal tready   : std_logic := '0';
  signal overflow : std_logic;

  signal sets     : set_arr := (others => (others => '0'));
  signal n_sent   : integer := 0;     -- number of in_valid strobes issued
  signal p_low    : real    := 0.4;   -- probability of tready = '0'
  signal strict   : boolean := true;  -- no losses allowed
  signal done     : boolean := false;

  -- monitor results, read by the stimulus process
  signal matched  : integer := 0;     -- bursts that matched an input set
  signal last_set : integer := -1;    -- index of the last matched set
  signal dropped  : integer := 0;
  signal mon_err  : integer := 0;

begin

  clk <= not clk after 4 ns when not done else '0';

  dut : entity work.tdm_interleave
    generic map (n_ch => n_ch, width => width)
    port map (clk, reset, in_data, in_valid, tdata, tvalid, tlast, tready, overflow);

  stim : process is
    variable seed1, seed2 : positive := 11;
    variable r : real;
    variable v : std_logic_vector(n_ch * width - 1 downto 0);
    variable k : integer := 0;
    variable errors : integer := 0;

    procedure tick (n : integer) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure tick;

    procedure send_set is
    begin
      for b in v'range loop
        uniform(seed1, seed2, r);
        if r < 0.5 then v(b) := '0'; else v(b) := '1'; end if;
      end loop;
      in_data  <= v;
      sets(k)  <= v;
      in_valid <= '1';
      k := k + 1;
      n_sent <= k;
      tick(1);
      in_valid <= '0';
    end procedure send_set;

  begin
    tick(3);
    reset <= '0';
    tick(2);

    -- phase 1
    p_low <= 0.4;
    for i in 1 to n_p1 loop
      send_set;
      tick(29);
    end loop;
    tick(60);
    if matched /= n_p1 or last_set /= n_p1 - 1 or overflow /= '0' then
      errors := errors + 1;
      report "phase 1: matched " & integer'image(matched) & " of " & integer'image(n_p1)
        & ", overflow=" & std_logic'image(overflow) severity error;
    end if;
    report "phase 1: " & integer'image(matched) & " bursts checked, "
      & integer'image(n_p1 - matched) & " lost, overflow="
      & std_logic'image(overflow);

    -- phase 2
    strict <= false;
    p_low  <= 0.75;
    for i in 1 to n_p2 loop
      send_set;
      tick(4);
    end loop;
    p_low <= 0.4;
    tick(100);
    if overflow /= '1' or dropped = 0 then
      errors := errors + 1;
      report "phase 2: overflow not detected" severity error;
    end if;
    report "phase 2: " & integer'image(matched - n_p1) & " bursts delivered, "
      & integer'image(dropped) & " sets dropped, overflow=" & std_logic'image(overflow);

    -- phase 3: reset two beats into a burst
    send_set;
    tick(4);
    reset <= '1';
    tick(1);
    reset <= '0';
    wait for 1 ns;
    if tvalid /= '0' or overflow /= '0' then
      errors := errors + 1;
      report "phase 3: tvalid/overflow not cleared by reset" severity error;
    end if;
    tick(5);
    strict <= true;
    for i in 1 to n_p3 loop
      send_set;
      tick(29);
    end loop;
    tick(60);
    if last_set /= k - 1 or overflow /= '0' then
      errors := errors + 1;
      report "phase 3: last set " & integer'image(last_set) & " exp " & integer'image(k - 1)
        severity error;
    end if;

    errors := errors + mon_err;
    report "tdm_interleave: " & integer'image(matched) & " bursts checked ("
      & integer'image(matched * n_ch) & " beats), " & integer'image(dropped)
      & " sets dropped under overload, " & integer'image(errors) & " errors";
    assert errors = 0 report "tb_tdm_interleave FAILED" severity failure;
    done <= true;
    wait;
  end process stim;

  monitor : process (clk) is
    variable seed1, seed2 : positive := 5;
    variable r : real;
    type beat_arr is array (0 to n_ch - 1) of std_logic_vector(width - 1 downto 0);
    variable burst : beat_arr;
    variable nb : integer := 0;
    variable found : integer;
    variable errors : integer := 0;
    variable prev_stall : boolean := false;
    variable prev_data : std_logic_vector(width - 1 downto 0);
    variable prev_last : std_logic;
    variable ls : integer := -1;
    variable n_match, n_drop : integer := 0;
    variable resync : boolean := false; -- after a reset the next burst may skip sets

    procedure err (msg : string) is
    begin
      errors := errors + 1;
      if errors < 10 then report msg severity error; end if;
    end procedure err;

    impure function match (j : integer; b : beat_arr) return boolean is
    begin
      for c in 0 to n_ch - 1 loop
        if sets(j)((c + 1) * width - 1 downto c * width) /= b(c) then return false; end if;
      end loop;
      return true;
    end function match;

  begin
    if rising_edge(clk) then
      if reset = '1' then
        nb := 0;
        prev_stall := false;
        resync := true;
      else
        -- AXI-Stream stability after a stalled cycle
        if prev_stall then
          if tvalid /= '1' or tdata /= prev_data or tlast /= prev_last then
            err("AXI stability violated");
          end if;
        end if;
        prev_stall := tvalid = '1' and tready /= '1';
        prev_data := tdata;
        prev_last := tlast;

        if tvalid = '1' and tready = '1' then
          burst(nb) := tdata;
          if (tlast = '1') /= (nb = n_ch - 1) then
            err("tlast on beat " & integer'image(nb));
            nb := 0;
          elsif nb = n_ch - 1 then
            -- complete burst: find the matching input set after the last one
            found := -1;
            for j in ls + 1 to n_sent - 1 loop
              if match(j, burst) then found := j; exit; end if;
            end loop;
            if found < 0 then
              err("burst matches no input set after " & integer'image(ls));
            else
              if found /= ls + 1 then
                if strict and not resync then
                  err("lost sets " & integer'image(ls + 1) & " .. " & integer'image(found - 1));
                end if;
                if not resync then n_drop := n_drop + found - ls - 1; end if;
              end if;
              resync := false;
              ls := found;
              n_match := n_match + 1;
            end if;
            nb := 0;
          else
            nb := nb + 1;
          end if;
        end if;
      end if;

      matched  <= n_match;
      last_set <= ls;
      dropped  <= n_drop;
      mon_err  <= errors;

      uniform(seed1, seed2, r);
      if r < p_low then tready <= '0'; else tready <= '1'; end if;
    end if;
  end process monitor;

end architecture sim;
