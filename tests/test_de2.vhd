--
-- DE2 top-level module that includes the simple audio component
--
-- From JCLL, jean-christophe.le_lann@ensta-bretagne.fr
-- ...From Stephen A. Edwards, Columbia University, sedwards@cs.columbia.edu
-- ......From an original by Terasic Technology, Inc.
-- ......(DE2_TOP.v, part of the DE2 system board CD supplied by Altera)
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DE2 is

  port (
    -- Clocks

    CLOCK_27  : in std_logic;           -- 27 MHz
    CLOCK_50  : in std_logic;           -- 50 MHz
    EXT_CLOCK : in std_logic;           -- External Clock

    -- Buttons and switches

    KEY : in std_logic_vector(3 downto 0);   -- Push buttons
    SW  : in std_logic_vector(17 downto 0);  -- DPDT switches

    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7  : out std_logic_vector(6 downto 0);-- 7-segment displays
    LEDG : out std_logic_vector(7 downto 0);        -- Green LEDs
    LEDR : out std_logic_vector(17 downto 0);       -- Red LEDs

    -- RS-232 interface

    UART_TXD : out std_logic;           -- UART transmitter
    UART_RXD : in  std_logic;           -- UART receiver

    -- IRDA interface

--    IRDA_TXD : out std_logic;                      -- IRDA Transmitter
    IRDA_RXD : in std_logic;            -- IRDA Receiver

    -- SDRAM

    DRAM_DQ    : inout std_logic_vector(15 downto 0);  -- Data Bus
    DRAM_ADDR  : out   std_logic_vector(11 downto 0);  -- Address Bus
    DRAM_LDQM  : out   std_logic;                      -- Low-byte Data Mask
    DRAM_UDQM  : out   std_logic;                      -- High-byte Data Mask
    DRAM_WE_N  : out   std_logic;                      -- Write Enable
    DRAM_CAS_N : out   std_logic;                      -- Column Address Strobe
    DRAM_RAS_N : out   std_logic;                      -- Row Address Strobe
    DRAM_CS_N  : out   std_logic;                      -- Chip Select
    DRAM_BA_0  : out   std_logic;                      -- Bank Address 0
    DRAM_BA_1  : out   std_logic;                      -- Bank Address 0
    DRAM_CLK   : out   std_logic;                      -- Clock
    DRAM_CKE   : out   std_logic;                      -- Clock Enable

    -- FLASH

    FL_DQ    : inout std_logic_vector(7 downto 0);   -- Data bus
    FL_ADDR  : out   std_logic_vector(21 downto 0);  -- Address bus
    FL_WE_N  : out   std_logic;                      -- Write Enable
    FL_RST_N : out   std_logic;                      -- Reset
    FL_OE_N  : out   std_logic;                      -- Output Enable
    FL_CE_N  : out   std_logic;                      -- Chip Enable

    -- SRAM

    SRAM_DQ   : inout std_logic_vector(15 downto 0);  -- Data bus 16 Bits
    SRAM_ADDR : out   std_logic_vector(17 downto 0);  -- Address bus 18 Bits
    SRAM_UB_N : out   std_logic;                      -- High-byte Data Mask
    SRAM_LB_N : out   std_logic;                      -- Low-byte Data Mask
    SRAM_WE_N : out   std_logic;                      -- Write Enable
    SRAM_CE_N : out   std_logic;                      -- Chip Enable
    SRAM_OE_N : out   std_logic;                      -- Output Enable

    -- USB controller

    OTG_DATA    : inout std_logic_vector(15 downto 0);  -- Data bus
    OTG_ADDR    : out   std_logic_vector(1 downto 0);   -- Address
    OTG_CS_N    : out   std_logic;      -- Chip Select
    OTG_RD_N    : out   std_logic;      -- Write
    OTG_WR_N    : out   std_logic;      -- Read
    OTG_RST_N   : out   std_logic;      -- Reset
    OTG_FSPEED  : out   std_logic;  -- USB Full Speed, 0 = Enable, Z = Disable
    OTG_LSPEED  : out   std_logic;  -- USB Low Speed, 0 = Enable, Z = Disable
    OTG_INT0    : in    std_logic;      -- Interrupt 0
    OTG_INT1    : in    std_logic;      -- Interrupt 1
    OTG_DREQ0   : in    std_logic;      -- DMA Request 0
    OTG_DREQ1   : in    std_logic;      -- DMA Request 1
    OTG_DACK0_N : out   std_logic;      -- DMA Acknowledge 0
    OTG_DACK1_N : out   std_logic;      -- DMA Acknowledge 1

    -- 16 X 2 LCD Module

    LCD_ON,                             -- Power ON/OFF
    LCD_BLON,                           -- Back Light ON/OFF
    LCD_RW,                      -- Read/Write Select, 0 = Write, 1 = Read
    LCD_EN,                             -- Enable
    LCD_RS   : out   std_logic;  -- Command/Data Select, 0 = Command, 1 = Data
    LCD_DATA : inout std_logic_vector(7 downto 0);  -- Data bus 8 bits

    -- SD card interface

    SD_DAT,                             -- SD Card Data
    SD_DAT3,                            -- SD Card Data 3
    SD_CMD : inout std_logic;           -- SD Card Command Signal
    SD_CLK : out   std_logic;           -- SD Card Clock

    -- USB JTAG link

    TDI,                                -- CPLD -> FPGA (data in)
    TCK,                                -- CPLD -> FPGA (clk)
    TCS : in  std_logic;                -- CPLD -> FPGA (CS)
    TDO : out std_logic;                -- FPGA -> CPLD (data out)

    -- I2C bus

    I2C_SDAT : inout std_logic;         -- I2C Data
    I2C_SCLK : out   std_logic;         -- I2C Clock

    -- PS/2 port

    PS2_DAT,                            -- Data
    PS2_CLK : in std_logic;             -- Clock

    -- VGA output

    VGA_CLK,                                      -- Clock
    VGA_HS,                                       -- H_SYNC
    VGA_VS,                                       -- V_SYNC
    VGA_BLANK,                                    -- BLANK
    VGA_SYNC : out std_logic;                     -- SYNC
    VGA_R,                                        -- Red[9:0]
    VGA_G,                                        -- Green[9:0]
    VGA_B    : out std_logic_vector(9 downto 0);  -- Blue[9:0]

    --  Ethernet Interface

    ENET_DATA : inout std_logic_vector(15 downto 0);  -- DATA bus 16Bits
    ENET_CMD,  -- Command/Data Select, 0 = Command, 1 = Data
    ENET_CS_N,                          -- Chip Select
    ENET_WR_N,                          -- Write
    ENET_RD_N,                          -- Read
    ENET_RST_N,                         -- Reset
    ENET_CLK  : out   std_logic;        -- Clock 25 MHz
    ENET_INT  : in    std_logic;        -- Interrupt

    -- Audio CODEC

    AUD_ADCLRCK : inout std_logic;      -- ADC LR Clock
    AUD_ADCDAT  : in    std_logic;      -- ADC Data
    AUD_DACLRCK : inout std_logic;      -- DAC LR Clock
    AUD_DACDAT  : out   std_logic;      -- DAC Data
    AUD_BCLK    : inout std_logic;      -- Bit-Stream Clock
    AUD_XCK     : out   std_logic;      -- Chip Clock

    -- Video Decoder

    TD_DATA  : in  std_logic_vector(7 downto 0);  -- Data bus 8 bits
    TD_HS,                                        -- H_SYNC
    TD_VS    : in  std_logic;                     -- V_SYNC
    TD_RESET : out std_logic;                     -- Reset

    -- General-purpose I/O

    GPIO_0,                                       -- GPIO Connection 0
    GPIO_1 : inout std_logic_vector(35 downto 0)  -- GPIO Connection 1
    );

end DE2;

architecture RTL of DE2 is
  signal reset_n   : std_logic;
  signal start     : std_logic;
  signal req_a     : std_logic;
  signal req_b     : std_logic;
  signal a, b      : std_logic_vector(3 downto 0);
  signal ready     : std_logic;
  signal res       : std_logic_vector(7 downto 0);
  signal state_o   : std_logic_vector(3 downto 0);  --one hot for LOGIC archi !
  signal state_num : std_logic_vector(3 downto 0);

  function binTo7Seg(bin : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable res : std_logic_vector(6 downto 0);
  begin
    res := "0000000";
    case bin is
      when "0000" => res := "0111111";  --0
      when "0001" => res := "0000110";  --1
      when "0010" => res := "1011011";  --2
      when "0011" => res := "1001111";  --3
      when "0100" => res := "1100110";  --4
      when "0101" => res := "1101101";  --5
      when "0110" => res := "1111101";  --6
      when "0111" => res := "0000111";  --7
      when "1000" => res := "1111111";  --8
      when "1001" => res := "1101111";  --9
      when "1010" => res := "1110111";  --A
      when "1011" => res := "1111100";  --b
      when "1100" => res := "0111001";  --C
      when "1101" => res := "1011110";  --d
      when "1110" => res := "1111001";  --E
      when "1111" => res := "1110001";  --F
      when others => null;
    end case;
    return res;
  end binTo7Seg;

  function one_hot_to_dec (bin : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable res : std_logic_vector(3 downto 0);
  begin
    res := "0000";
    for i in bin'range loop
      if bin(i) = '1' then
        return std_logic_vector(to_unsigned(i, 4));
      end if;
    end loop;
    return res;
  end one_hot_to_dec;

--=====================================================================
  signal sta : std_logic_vector(3 downto 0);
  constant PRESSED : std_logic :='0';
begin

  -----------------------------------------------------------------------------
  ---- inputs
  -----------------------------------------------------------------------------
  reset_n <= '0' when KEY(0)=PRESSED else '1';
  start   <= '1' when KEY(1)=PRESSED else '0';
  req_a   <= '1' when KEY(2)=PRESSED else '0';
  req_b   <= '1' when KEY(3)=PRESSED else '0';
  a       <= SW(3 downto 0);
  b       <= SW(3 downto 0);

  -------------------------------------------------------------------------------
  ---- outputs
  -------------------------------------------------------------------------------
  LEDG(0)   <= ready;
  HEX0 <= not binTo7Seg(res(3 downto 0)) when ready = '1' else
             not binTo7Seg(SW(3 downto 0));
  HEX1 <= not binTo7Seg(res(7 downto 4)) when ready = '1' else
          not "0001000";
  HEX5 <= not binTo7Seg("0101");        -- letter S
  HEX4 <= not binTo7Seg(state_num);     -- state number
  HEX2 <= not "0001000";                --nicer
  HEX3 <= not "0001000";
  HEX6 <= not "0001000";
  HEX7 <= not "0001000" when start='1' else "0001000";
  state_num <= one_hot_to_dec(state_o);


  DESIGN : entity work.MultSeq(logic)
    port map (
      clk     => CLOCK_27,
      reset_n => reset_n,
      start   => start,
      req_a   => req_a,
      req_b   => req_b,
      a       => a,
      b       => b,
      ready   => ready,
      res     => res,
      state_o => state_o
      );

  -----------------------------------------
  -- Unassigned
  -----------------------------------------
  LEDR <= (others => '0');

  -- LCD
  LCD_ON   <= '1';
  LCD_BLON <= '1';
  LCD_RW   <= '1';
  LCD_EN   <= '0';
  LCD_RS   <= '0';

  -- VGA
  VGA_CLK   <= '0';
  VGA_HS    <= '0';
  VGA_VS    <= '0';
  VGA_BLANK <= '0';
  VGA_SYNC  <= '0';
  VGA_R     <= (others => '0');
  VGA_G     <= (others => '0');
  VGA_B     <= (others => '0');

  --SD
  SD_DAT3 <= '1';
  SD_CMD  <= '1';
  SD_CLK  <= '1';

  -- SRAM
  SRAM_DQ   <= (others => 'Z');
  SRAM_ADDR <= (others => '0');
  SRAM_UB_N <= '1';
  SRAM_LB_N <= '1';
  SRAM_CE_N <= '1';
  SRAM_WE_N <= '1';
  SRAM_OE_N <= '1';

  UART_TXD <= '0';

  -- DRAM
  DRAM_ADDR  <= (others => '0');
  DRAM_LDQM  <= '0';
  DRAM_UDQM  <= '0';
  DRAM_WE_N  <= '1';
  DRAM_CAS_N <= '1';
  DRAM_RAS_N <= '1';
  DRAM_CS_N  <= '1';
  DRAM_BA_0  <= '0';
  DRAM_BA_1  <= '0';
  DRAM_CLK   <= '0';
  DRAM_CKE   <= '0';

  -- FLASH
  FL_ADDR     <= (others => '0');
  FL_WE_N     <= '1';
  FL_RST_N    <= '0';
  FL_OE_N     <= '1';
  FL_CE_N     <= '1';
  OTG_ADDR    <= (others => '0');
  OTG_CS_N    <= '1';
  OTG_RD_N    <= '1';
  OTG_RD_N    <= '1';
  OTG_WR_N    <= '1';
  OTG_RST_N   <= '1';
  OTG_FSPEED  <= '1';
  OTG_LSPEED  <= '1';
  OTG_DACK0_N <= '1';
  OTG_DACK1_N <= '1';

  TDO <= '0';

  -- ETHERNET
  ENET_CMD   <= '0';
  ENET_CS_N  <= '1';
  ENET_WR_N  <= '1';
  ENET_RD_N  <= '1';
  ENET_RST_N <= '1';
  ENET_CLK   <= '0';

  -- Video decoder
  TD_RESET <= '1';                      -- NEED TO ACTIVATE 27 Mhz

  -- Set all bidirectional ports to tri-state
  DRAM_DQ   <= (others => 'Z');
  FL_DQ     <= (others => 'Z');
  OTG_DATA  <= (others => 'Z');
  LCD_DATA  <= (others => 'Z');
  SD_DAT    <= 'Z';
  ENET_DATA <= (others => 'Z');
  GPIO_0    <= (others => 'Z');
  GPIO_1    <= (others => 'Z');

end RTL;
