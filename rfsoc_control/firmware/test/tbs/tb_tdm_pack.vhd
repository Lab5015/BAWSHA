library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

-- tdm_pack fed by a behavioural TDM source with random gaps (0..3 idle cycles
-- between beats, 0..10 between bursts, sometimes fully back-to-back).
-- Every correct burst must come out as one word equal to the input set, in
-- order. Malformed bursts are injected (missing tlast, early tlast, short and
-- long bursts): sync_error must go '1', the malformed burst must not be
-- published, and the next correct burst must be packed correctly.
entity tb_tdm_pack is
end entity tb_tdm_pack;

architecture sim of tb_tdm_pack is

  constant n_ch    : integer := 8;
  constant width   : integer := 32;
  constant n_words : integer := 1000;

  type word_arr is array (0 to n_words - 1) of std_logic_vector(n_ch * width - 1 downto 0);

  signal clk        : std_logic := '0';
  signal reset      : std_logic := '1';
  signal tdata      : std_logic_vector(width - 1 downto 0) := (others => '0');
  signal tvalid     : std_logic := '0';
  signal tlast      : std_logic := '0';
  signal out_data   : std_logic_vector(n_ch * width - 1 downto 0);
  signal out_valid  : std_logic;
  signal sync_error : std_logic;

  signal expected   : word_arr := (others => (others => '0'));
  signal n_exp      : integer := 0;  -- words that must be published
  signal n_got      : integer := 0;
  signal mon_err    : integer := 0;
  signal done       : boolean := false;

begin

  clk <= not clk after 4 ns when not done else '0';

  dut : entity work.tdm_pack
    generic map (n_ch => n_ch, width => width)
    port map (clk, reset, tdata, tvalid, tlast, out_data, out_valid, sync_error);

  stim : process is
    variable seed1, seed2 : positive := 23;
    variable r : real;
    variable v : std_logic_vector(n_ch * width - 1 downto 0);
    variable k : integer := 0;
    variable errors : integer := 0;
    variable n_inj : integer := 0;
    variable back_to_back : boolean;
    variable n_short : integer;

    procedure tick (n : integer) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure tick;

    impure function rnd (n : integer) return integer is
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n + 1)));
    end function rnd;

    -- send n_beats beats of v, tlast on beat tlast_at (-1: never)
    procedure burst (n_beats, tlast_at : integer) is
    begin
      for b in 0 to n_beats - 1 loop
        tdata  <= v((b mod n_ch + 1) * width - 1 downto (b mod n_ch) * width);
        tvalid <= '1';
        if b = tlast_at then tlast <= '1'; else tlast <= '0'; end if;
        tick(1);
        tvalid <= '0';
        tlast  <= '0';
        if not back_to_back then tick(rnd(3)); end if;
      end loop;
    end procedure burst;

    procedure new_set is
    begin
      for b in v'range loop
        uniform(seed1, seed2, r);
        if r < 0.5 then v(b) := '0'; else v(b) := '1'; end if;
      end loop;
    end procedure new_set;

    procedure good_burst is
    begin
      new_set;
      expected(k) <= v;
      k := k + 1;
      n_exp <= k;
      burst(n_ch, n_ch - 1);
    end procedure good_burst;

    procedure check_err (name : string) is
    begin
      tick(2);
      n_inj := n_inj + 1;
      if sync_error /= '1' then
        errors := errors + 1;
        report name & ": sync_error not set" severity error;
      end if;
    end procedure check_err;

    procedure clear_err is
    begin
      reset <= '1';
      tick(1);
      reset <= '0';
      tick(1);
    end procedure clear_err;

  begin
    tick(3);
    reset <= '0';
    tick(2);

    for i in 1 to 600 loop
      back_to_back := i mod 5 = 0;
      good_burst;
      if not back_to_back then tick(rnd(10)); end if;
    end loop;
    tick(5);
    if sync_error /= '0' then
      errors := errors + 1;
      report "sync_error set on clean stream" severity error;
    end if;

    -- After each injection the following correct bursts are sent WITHOUT a
    -- reset and must be packed (resync on tlast). sync_error must still be '1'
    -- (sticky), then a reset clears it before the next case.
    for i in 1 to 40 loop
      back_to_back := i mod 3 = 0;
      -- missing tlast
      new_set; burst(n_ch, -1);
      good_burst; good_burst; check_err("missing tlast"); clear_err;
      -- short burst ending with tlast
      new_set; n_short := 1 + rnd(n_ch - 2); burst(n_short, n_short - 1);
      good_burst; good_burst; check_err("short burst"); clear_err;
      -- 12-beat burst with tlast at the end
      new_set; burst(n_ch + 4, n_ch + 3);
      good_burst; check_err("long burst"); clear_err;
      -- early tlast inside a full 8-beat burst: the beats after it start a new
      -- (misaligned) word, so the following burst is legitimately lost too
      -- (sent but not expected). The packer is aligned again after its tlast.
      new_set; burst(n_ch, rnd(n_ch - 2));
      new_set; burst(n_ch, n_ch - 1);
      good_burst; good_burst; check_err("early tlast"); clear_err;
    end loop;
    tick(10);

    -- the clean bursts after each injection must restore the stream
    if sync_error /= '0' then
      errors := errors + 1;
      report "sync_error set on clean stream after resync" severity error;
    end if;
    if n_got /= k then
      errors := errors + 1;
      report "words published " & integer'image(n_got) & " expected " & integer'image(k) severity error;
    end if;

    errors := errors + mon_err;
    report "tdm_pack: " & integer'image(n_got) & " words checked, " & integer'image(n_inj)
      & " framing errors injected and detected, " & integer'image(errors) & " errors";
    assert errors = 0 report "tb_tdm_pack FAILED" severity failure;
    done <= true;
    wait;
  end process stim;

  monitor : process (clk) is
    variable got, errors : integer := 0;
  begin
    if rising_edge(clk) then
      if out_valid = '1' then
        if got >= n_exp then
          errors := errors + 1;
          report "unexpected word published" severity error;
        elsif out_data /= expected(got) then
          errors := errors + 1;
          if errors < 10 then report "word " & integer'image(got) & " mismatch" severity error; end if;
        end if;
        got := got + 1;
      end if;
      n_got   <= got;
      mon_err <= errors;
    end if;
  end process monitor;

end architecture sim;
