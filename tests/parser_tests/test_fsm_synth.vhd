library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity fsm is
  port (
    reset_n: in std_logic;
    clk: in std_logic;
    switches: in std_logic_vector (7 downto 0);
    leds: out std_logic_vector (7 downto 0);
    o1, o2: out std_logic;
    o3: out unsigned (3 downto 0)
  );
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of fsm is
  signal wrap_reset_n: std_logic;
  signal wrap_clk: std_logic;
  signal wrap_switches: std_logic_vector (7 downto 0);
  signal wrap_leds: std_logic_vector (7 downto 0);
  signal wrap_o1: std_logic;
  signal wrap_o2: std_logic;
  signal wrap_o3: std_logic_vector (3 downto 0);
  signal state : std_logic_vector (2 downto 0);
  signal state_c : std_logic_vector (2 downto 0);
  signal c3 : std_logic_vector (3 downto 0);
  signal n7_o : std_logic;
  signal n12_q : std_logic_vector (2 downto 0);
  signal n17_o : std_logic;
  signal n19_o : std_logic_vector (2 downto 0);
  signal n20_o : std_logic;
  signal n22_o : std_logic_vector (2 downto 0);
  signal n23_o : std_logic;
  signal n25_o : std_logic_vector (2 downto 0);
  signal n26_o : std_logic;
  signal n28_o : std_logic_vector (2 downto 0);
  signal n29_o : std_logic;
  signal n31_o : std_logic_vector (2 downto 0);
  signal n32_o : std_logic;
  signal n35_o : std_logic;
  signal n36_o : std_logic_vector (2 downto 0);
  signal n37_o : std_logic;
  signal n40_o : std_logic;
  signal n41_o : std_logic_vector (2 downto 0);
  signal n42_o : std_logic;
  signal n44_o : std_logic_vector (2 downto 0);
  signal n45_o : std_logic_vector (1 downto 0);
  signal n46_o : std_logic;
  signal n47_o : std_logic;
  signal n48_o : std_logic;
  signal n49_o : std_logic;
  signal n50_o : std_logic_vector (1 downto 0);
  signal n51_o : std_logic;
  signal n52_o : std_logic;
  signal n53_o : std_logic;
  signal n54_o : std_logic;
  signal n55_o : std_logic_vector (1 downto 0);
  signal n56_o : std_logic_vector (2 downto 0);
  signal n57_o : std_logic_vector (2 downto 0);
  signal n58_o : std_logic;
  signal n59_o : std_logic_vector (2 downto 0);
  signal n63_o : std_logic;
  signal n64_o : std_logic_vector (7 downto 0);
  signal n67_o : std_logic;
  signal n68_o : std_logic_vector (7 downto 0);
  signal n71_o : std_logic;
  signal n72_o : std_logic_vector (7 downto 0);
  signal n75_o : std_logic;
  signal n76_o : std_logic_vector (7 downto 0);
  signal n79_o : std_logic;
  signal n80_o : std_logic_vector (7 downto 0);
  signal n83_o : std_logic;
  signal n84_o : std_logic_vector (7 downto 0);
  signal n87_o : std_logic;
  signal n88_o : std_logic_vector (7 downto 0);
  signal n92_o : std_logic;
  signal n96_o : std_logic_vector (3 downto 0);
  signal n99_q : std_logic_vector (3 downto 0);
begin
  wrap_reset_n <= reset_n;
  wrap_clk <= clk;
  wrap_switches <= switches;
  leds <= wrap_leds;
  o1 <= wrap_o1;
  o2 <= wrap_o2;
  o3 <= unsigned(wrap_o3);
  wrap_leds <= n64_o;
  wrap_o1 <= n49_o;
  wrap_o2 <= n54_o;
  wrap_o3 <= c3;
  -- fsm.vhd:18:10
  state <= n12_q; -- (signal)
  -- fsm.vhd:18:16
  state_c <= n59_o; -- (signal)
  -- fsm.vhd:20:10
  c3 <= n99_q; -- (signal)
  -- fsm.vhd:24:15
  n7_o <= not wrap_reset_n;
  -- fsm.vhd:26:5
  process (wrap_clk, n7_o)
  begin
    if n7_o = '1' then
      n12_q <= "000";
    elsif rising_edge (wrap_clk) then
      n12_q <= state_c;
    end if;
  end process;
  -- fsm.vhd:39:20
  n17_o <= wrap_switches (0);
  -- fsm.vhd:39:9
  n19_o <= state when n17_o = '0' else "001";
  -- fsm.vhd:43:20
  n20_o <= wrap_switches (1);
  -- fsm.vhd:43:9
  n22_o <= state when n20_o = '0' else "010";
  -- fsm.vhd:47:20
  n23_o <= wrap_switches (2);
  -- fsm.vhd:47:9
  n25_o <= state when n23_o = '0' else "011";
  -- fsm.vhd:51:20
  n26_o <= wrap_switches (3);
  -- fsm.vhd:51:9
  n28_o <= state when n26_o = '0' else "100";
  -- fsm.vhd:55:20
  n29_o <= wrap_switches (4);
  -- fsm.vhd:55:9
  n31_o <= state when n29_o = '0' else "101";
  -- fsm.vhd:59:20
  n32_o <= wrap_switches (5);
  -- fsm.vhd:59:9
  n35_o <= '0' when n32_o = '0' else '1';
  -- fsm.vhd:59:9
  n36_o <= state when n32_o = '0' else "110";
  -- fsm.vhd:64:20
  n37_o <= wrap_switches (6);
  -- fsm.vhd:64:9
  n40_o <= '1' when n37_o = '0' else '1';
  -- fsm.vhd:64:9
  n41_o <= state when n37_o = '0' else "111";
  -- fsm.vhd:69:20
  n42_o <= wrap_switches (7);
  -- fsm.vhd:69:9
  n44_o <= state when n42_o = '0' else "000";
  -- fsm.vhd:37:10
  n45_o <= state (1 downto 0);
  -- fsm.vhd:37:10
  with n45_o select n46_o <=
    '0' when "00",
    '0' when "01",
    '0' when "10",
    '0' when "11",
    'X' when others;
  -- fsm.vhd:37:10
  with n45_o select n47_o <=
    '0' when "00",
    n35_o when "01",
    '0' when "10",
    '0' when "11",
    'X' when others;
  -- fsm.vhd:37:10
  n48_o <= state (2);
  -- fsm.vhd:37:10
  n49_o <= n46_o when n48_o = '0' else n47_o;
  -- fsm.vhd:37:10
  n50_o <= state (1 downto 0);
  -- fsm.vhd:37:10
  with n50_o select n51_o <=
    '1' when "00",
    '1' when "01",
    '1' when "10",
    '1' when "11",
    'X' when others;
  -- fsm.vhd:37:10
  with n50_o select n52_o <=
    '1' when "00",
    '1' when "01",
    n40_o when "10",
    '1' when "11",
    'X' when others;
  -- fsm.vhd:37:10
  n53_o <= state (2);
  -- fsm.vhd:37:10
  n54_o <= n51_o when n53_o = '0' else n52_o;
  -- fsm.vhd:37:10
  n55_o <= state (1 downto 0);
  -- fsm.vhd:37:10
  with n55_o select n56_o <=
    n19_o when "00",
    n22_o when "01",
    n25_o when "10",
    n28_o when "11",
    "XXX" when others;
  -- fsm.vhd:37:10
  with n55_o select n57_o <=
    n31_o when "00",
    n36_o when "01",
    n41_o when "10",
    n44_o when "11",
    "XXX" when others;
  -- fsm.vhd:37:10
  n58_o <= state (2);
  -- fsm.vhd:37:10
  n59_o <= n56_o when n58_o = '0' else n57_o;
  -- fsm.vhd:79:56
  n63_o <= '1' when state = "000" else '0';
  -- fsm.vhd:79:46
  n64_o <= n68_o when n63_o = '0' else "00000000";
  -- fsm.vhd:80:56
  n67_o <= '1' when state = "001" else '0';
  -- fsm.vhd:79:60
  n68_o <= n72_o when n67_o = '0' else "00000001";
  -- fsm.vhd:81:56
  n71_o <= '1' when state = "010" else '0';
  -- fsm.vhd:80:60
  n72_o <= n76_o when n71_o = '0' else "00000010";
  -- fsm.vhd:82:56
  n75_o <= '1' when state = "011" else '0';
  -- fsm.vhd:81:60
  n76_o <= n80_o when n75_o = '0' else "00000011";
  -- fsm.vhd:83:56
  n79_o <= '1' when state = "100" else '0';
  -- fsm.vhd:82:60
  n80_o <= n84_o when n79_o = '0' else "00000100";
  -- fsm.vhd:84:56
  n83_o <= '1' when state = "101" else '0';
  -- fsm.vhd:83:60
  n84_o <= n88_o when n83_o = '0' else "00000101";
  -- fsm.vhd:85:56
  n87_o <= '1' when state = "110" else '0';
  -- fsm.vhd:84:60
  n88_o <= "00000111" when n87_o = '0' else "00000110";
  -- fsm.vhd:90:15
  n92_o <= not wrap_reset_n;
  -- fsm.vhd:93:16
  n96_o <= std_logic_vector (unsigned (c3) + unsigned'("0001"));
  -- fsm.vhd:92:5
  process (wrap_clk, n92_o)
  begin
    if n92_o = '1' then
      n99_q <= "0000";
    elsif rising_edge (wrap_clk) then
      n99_q <= n96_o;
    end if;
  end process;
end rtl;
