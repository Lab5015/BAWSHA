library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity global_axi_control_v1_0 is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Parameters of Axi Slave Bus Interface S00_AXI
    c_s00_axi_data_width : integer := 32;
    c_s00_axi_addr_width : integer := 4
  );
  port (
    -- Users to add ports here
    reset       : out   std_logic;
    resetn      : out   std_logic;
    config_port : out   std_logic;
    run         : out   std_logic;
    clk_adc     : in    std_logic;
    ext_start   : in    std_logic;

    -- User ports ends
    -- Do not modify the ports beyond this line

    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk    : in    std_logic;
    s00_axi_aresetn : in    std_logic;
    s00_axi_awaddr  : in    std_logic_vector(c_s00_axi_addr_width - 1 downto 0);
    s00_axi_awprot  : in    std_logic_vector(2 downto 0);
    s00_axi_awvalid : in    std_logic;
    s00_axi_awready : out   std_logic;
    s00_axi_wdata   : in    std_logic_vector(c_s00_axi_data_width - 1 downto 0);
    s00_axi_wstrb   : in    std_logic_vector((c_s00_axi_data_width / 8) - 1 downto 0);
    s00_axi_wvalid  : in    std_logic;
    s00_axi_wready  : out   std_logic;
    s00_axi_bresp   : out   std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out   std_logic;
    s00_axi_bready  : in    std_logic;
    s00_axi_araddr  : in    std_logic_vector(c_s00_axi_addr_width - 1 downto 0);
    s00_axi_arprot  : in    std_logic_vector(2 downto 0);
    s00_axi_arvalid : in    std_logic;
    s00_axi_arready : out   std_logic;
    s00_axi_rdata   : out   std_logic_vector(c_s00_axi_data_width - 1 downto 0);
    s00_axi_rresp   : out   std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out   std_logic;
    s00_axi_rready  : in    std_logic
  );
end entity global_axi_control_v1_0;

architecture arch_imp of global_axi_control_v1_0 is

  -- component declaration
  component global_axi_control_v1_0_s00_axi is
    generic (
      c_s_axi_data_width : integer  := 32;
      c_s_axi_addr_width : integer  := 4
    );
    port (
      control       : out   std_logic_vector(2 downto 0);
      s_axi_aclk    : in    std_logic;
      s_axi_aresetn : in    std_logic;
      s_axi_awaddr  : in    std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
      s_axi_awprot  : in    std_logic_vector(2 downto 0);
      s_axi_awvalid : in    std_logic;
      s_axi_awready : out   std_logic;
      s_axi_wdata   : in    std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
      s_axi_wstrb   : in    std_logic_vector((C_S_AXI_DATA_WIDTH / 8) - 1 downto 0);
      s_axi_wvalid  : in    std_logic;
      s_axi_wready  : out   std_logic;
      s_axi_bresp   : out   std_logic_vector(1 downto 0);
      s_axi_bvalid  : out   std_logic;
      s_axi_bready  : in    std_logic;
      s_axi_araddr  : in    std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
      s_axi_arprot  : in    std_logic_vector(2 downto 0);
      s_axi_arvalid : in    std_logic;
      s_axi_arready : out   std_logic;
      s_axi_rdata   : out   std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
      s_axi_rresp   : out   std_logic_vector(1 downto 0);
      s_axi_rvalid  : out   std_logic;
      s_axi_rready  : in    std_logic
    );
  end component global_axi_control_v1_0_s00_axi;

  signal control      : std_logic_vector(2 downto 0) := (others => '0');
  signal sync_control : std_logic_vector(2 downto 0) := (others => '0');

begin

  -- Instantiation of Axi Bus Interface S00_AXI
  global_axi_control_v1_0_s00_axi_inst : component global_axi_control_v1_0_s00_axi
    generic map (
      c_s_axi_data_width => C_S00_AXI_DATA_WIDTH,
      c_s_axi_addr_width => C_S00_AXI_ADDR_WIDTH
    )
    port map (
      control       => control,
      s_axi_aclk    => s00_axi_aclk,
      s_axi_aresetn => s00_axi_aresetn,
      s_axi_awaddr  => s00_axi_awaddr,
      s_axi_awprot  => s00_axi_awprot,
      s_axi_awvalid => s00_axi_awvalid,
      s_axi_awready => s00_axi_awready,
      s_axi_wdata   => s00_axi_wdata,
      s_axi_wstrb   => s00_axi_wstrb,
      s_axi_wvalid  => s00_axi_wvalid,
      s_axi_wready  => s00_axi_wready,
      s_axi_bresp   => s00_axi_bresp,
      s_axi_bvalid  => s00_axi_bvalid,
      s_axi_bready  => s00_axi_bready,
      s_axi_araddr  => s00_axi_araddr,
      s_axi_arprot  => s00_axi_arprot,
      s_axi_arvalid => s00_axi_arvalid,
      s_axi_arready => s00_axi_arready,
      s_axi_rdata   => s00_axi_rdata,
      s_axi_rresp   => s00_axi_rresp,
      s_axi_rvalid  => s00_axi_rvalid,
      s_axi_rready  => s00_axi_rready
    );

  -- Add user logic here

  sync : process (clk_adc) is
  begin

    if rising_edge(clk_adc) then
      sync_control <= control;
    end if;

  end process sync;

  translate_ctrl : process (clk_adc) is
  begin

    if rising_edge(clk_adc) then
      if (sync_control(0) = '1') then
        reset       <= '1';
        resetn      <= '0';
        config_port <= '0';
        run         <= '0';
      elsif (sync_control(1) = '1') then
        reset       <= '0';
        resetn      <= '1';
        config_port <= '1';
        run         <= '0';
      elsif (sync_control(2) = '1') then
        reset       <= '0';
        resetn      <= '1';
        config_port <= '0';
        run         <= '1' and ext_start;
      else
        reset       <= '0';
        resetn      <= '1';
        config_port <= '0';
        run         <= '0';
      end if;
    end if;

  end process translate_ctrl;

-- User logic ends

end architecture arch_imp;
