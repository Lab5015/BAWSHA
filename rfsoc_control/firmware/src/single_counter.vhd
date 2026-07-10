library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sing_counter_mod is
  port (
    clk : in    std_logic;
    run : in    std_logic;
    rst : in    std_logic;
    s_axis_tdata  : in    std_logic_vector(255 downto 0);
    s_axis_tvalid : in    std_logic;
    s_axis_tready : out   std_logic;
    m_axis_tdata  : out   std_logic_vector(255 downto 0);
    m_axis_tvalid : out   std_logic;
    m_axis_tready : in    std_logic;
    dropped : in    std_logic;
    counter_port : out   std_logic_vector(63 downto 0)
  );
end entity sing_counter_mod;

architecture behav of sing_counter_mod is
  signal internal_counter : unsigned(63 downto 0) := (others => '0');
  signal small_counter    : unsigned(7 downto 0)  := (others => '0');
  signal tdata_reg        : std_logic_vector(255 downto 0) := (others => '0');
  signal tvalid_reg       : std_logic := '0';
  signal handshake        : std_logic;
  
begin
  -- Handshake: transazione valida quando sia input che output sono pronti
  handshake <= s_axis_tvalid and m_axis_tready;
  s_axis_tready <= m_axis_tready;
  
  -- Registro di uscita
  pass : process (clk) is
  begin
    if rising_edge(clk) then
      if handshake = '1' then
        tdata_reg <= s_axis_tdata;
        tvalid_reg <= '1';
      elsif m_axis_tready = '1' then
        tvalid_reg <= '0';  -- Svuota il registro quando il destinatario legge
      end if;
    end if;
  end process pass;
  
  m_axis_tdata <= tdata_reg;
  m_axis_tvalid <= tvalid_reg;
  
  -- Contatori
  count : process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        internal_counter <= (others => '0');
        small_counter <= (others => '0');
      elsif run = '1' then
        internal_counter <= internal_counter + 1;
        
        -- Incrementa small_counter solo su handshake valido
        if handshake = '1' then
          if small_counter = "11111111" then
            small_counter <= (others => '0');  -- Resetta quando raggiunge 255
            counter_port <= std_logic_vector(internal_counter);  -- Salva il contatore
          else
            small_counter <= small_counter + 1;
          end if;
        end if;
      end if;
    end if;
  end process count;
  
end architecture behav;