-- ADC front-end: average the 12 samples that the RFDC delivers per fabric clock.
--
-- The RFDC runs at 1.47456 GS/s and presents 12 consecutive 16-bit samples per
-- 122.88 MHz clock (sample 0 in bits 15:0, sample 11 in bits 191:176).
-- Keeping only sample 0 (plain decimation by 12, no filtering) folds all the
-- noise/interference around k*122.88 MHz into the band of interest.
-- A 12-tap boxcar followed by decimation by 12 has exact nulls at k*122.88 MHz,
-- ~ -17 dB at (k*122.88 +- 20) MHz, unity gain at DC and ~ -0.4 dB droop at
-- 20 MHz, and adds ~ +5 dB of SNR on uncorrelated noise.
--
-- Output = round(sum(12 samples) * 5461 / 65536)  (5461/65536 ~ 1/12, error 6e-5).
-- Latency: 4 clock cycles, adc_valid_out is the delayed adc_data_valid.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity avg12 is
  port (
    clk            : in    std_logic;
    adc_data       : in    std_logic_vector(191 downto 0);
    adc_data_valid : in    std_logic;
    data_out       : out   std_logic_vector(15 downto 0);
    data_valid_out : out   std_logic
  );
end entity avg12;

architecture behav of avg12 is

  constant n_samples : integer := 12;
  constant recip     : signed(14 downto 0) := to_signed(5461, 15);

  type   sum3_t is array (0 to 3) of signed(17 downto 0);
  type   sum6_t is array (0 to 1) of signed(18 downto 0);

  signal s1    : sum3_t := (others => (others => '0'));
  signal s2    : sum6_t := (others => (others => '0'));
  signal s3    : signed(19 downto 0) := (others => '0');
  signal prod  : signed(34 downto 0) := (others => '0');
  signal vld   : std_logic_vector(3 downto 0) := (others => '0');

  function smp (v : std_logic_vector(191 downto 0); i : integer) return signed is
  begin
    return resize(signed(v(16 * i + 15 downto 16 * i)), 18);
  end function smp;

begin

  process (clk) is
  begin

    if rising_edge(clk) then
      -- stage 1: four partial sums of three samples
      for k in 0 to 3 loop
        s1(k) <= smp(adc_data, 3 * k) + smp(adc_data, 3 * k + 1) + smp(adc_data, 3 * k + 2);
      end loop;
      -- stage 2
      s2(0) <= resize(s1(0), 19) + resize(s1(1), 19);
      s2(1) <= resize(s1(2), 19) + resize(s1(3), 19);
      -- stage 3: total of the 12 samples
      s3 <= resize(s2(0), 20) + resize(s2(1), 20);
      -- stage 4: * 1/12 with rounding (+0.5 LSB = 32768 before the >>16)
      prod <= s3 * recip + to_signed(32768, 35);

      vld <= vld(2 downto 0) & adc_data_valid;
    end if;

  end process;

  data_out       <= std_logic_vector(prod(31 downto 16));
  data_valid_out <= vld(3);

end architecture behav;
