library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity fsm is
  port (
    reset_n: in std_logic;
    clk: in std_logic;
    switches: in std_logic_vector (7 downto 0);
    leds: out std_logic_vector (7 downto 0)
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
  signal state : std_logic_vector (2 downto 0);
  signal state_c : std_logic_vector (2 downto 0);
  signal n4_o : std_logic;
  signal n9_q : std_logic_vector (2 downto 0);
  signal n12_o : std_logic;
  signal n14_o : std_logic_vector (2 downto 0);
  signal n15_o : std_logic;
  signal n17_o : std_logic_vector (2 downto 0);
  signal n18_o : std_logic;
  signal n20_o : std_logic_vector (2 downto 0);
  signal n21_o : std_logic;
  signal n23_o : std_logic_vector (2 downto 0);
  signal n24_o : std_logic;
  signal n26_o : std_logic_vector (2 downto 0);
  signal n27_o : std_logic;
  signal n29_o : std_logic_vector (2 downto 0);
  signal n30_o : std_logic;
  signal n32_o : std_logic_vector (2 downto 0);
  signal n33_o : std_logic;
  signal n35_o : std_logic_vector (2 downto 0);
  signal n36_o : std_logic_vector (1 downto 0);
  signal n37_o : std_logic_vector (2 downto 0);
  signal n38_o : std_logic_vector (2 downto 0);
  signal n39_o : std_logic;
  signal n40_o : std_logic_vector (2 downto 0);
  signal n44_o : std_logic;
  signal n45_o : std_logic_vector (7 downto 0);
  signal n48_o : std_logic;
  signal n49_o : std_logic_vector (7 downto 0);
  signal n52_o : std_logic;
  signal n53_o : std_logic_vector (7 downto 0);
  signal n56_o : std_logic;
  signal n57_o : std_logic_vector (7 downto 0);
  signal n60_o : std_logic;
  signal n61_o : std_logic_vector (7 downto 0);
  signal n64_o : std_logic;
  signal n65_o : std_logic_vector (7 downto 0);
  signal n68_o : std_logic;
  signal n69_o : std_logic_vector (7 downto 0);
begin
  wrap_reset_n <= reset_n;
  wrap_clk <= clk;
  wrap_switches <= switches;
  leds <= wrap_leds;
  wrap_leds <= n45_o;
  -- fsm.vhd:16:10
  state <= n9_q; -- (signal)
  -- fsm.vhd:16:16
  state_c <= n40_o; -- (signal)
  -- fsm.vhd:20:15
  n4_o <= not wrap_reset_n;
  -- fsm.vhd:22:5
  process (wrap_clk, n4_o)
  begin
    if n4_o = '1' then
      n9_q <= "000";
    elsif rising_edge (wrap_clk) then
      n9_q <= state_c;
    end if;
  end process;
  -- fsm.vhd:33:20
  n12_o <= wrap_switches (0);
  -- fsm.vhd:33:9
  n14_o <= state when n12_o = '0' else "001";
  -- fsm.vhd:37:20
  n15_o <= wrap_switches (1);
  -- fsm.vhd:37:9
  n17_o <= state when n15_o = '0' else "010";
  -- fsm.vhd:41:20
  n18_o <= wrap_switches (2);
  -- fsm.vhd:41:9
  n20_o <= state when n18_o = '0' else "011";
  -- fsm.vhd:45:20
  n21_o <= wrap_switches (3);
  -- fsm.vhd:45:9
  n23_o <= state when n21_o = '0' else "100";
  -- fsm.vhd:49:20
  n24_o <= wrap_switches (4);
  -- fsm.vhd:49:9
  n26_o <= state when n24_o = '0' else "101";
  -- fsm.vhd:53:20
  n27_o <= wrap_switches (5);
  -- fsm.vhd:53:9
  n29_o <= state when n27_o = '0' else "110";
  -- fsm.vhd:57:20
  n30_o <= wrap_switches (6);
  -- fsm.vhd:57:9
  n32_o <= state when n30_o = '0' else "111";
  -- fsm.vhd:61:20
  n33_o <= wrap_switches (7);
  -- fsm.vhd:61:9
  n35_o <= state when n33_o = '0' else "000";
  -- fsm.vhd:31:10
  n36_o <= state (1 downto 0);
  -- fsm.vhd:31:10
  with n36_o select n37_o <=
    n14_o when "00",
    n17_o when "01",
    n20_o when "10",
    n23_o when "11",
    "XXX" when others;
  -- fsm.vhd:31:10
  with n36_o select n38_o <=
    n26_o when "00",
    n29_o when "01",
    n32_o when "10",
    n35_o when "11",
    "XXX" when others;
  -- fsm.vhd:31:10
  n39_o <= state (2);
  -- fsm.vhd:31:10
  n40_o <= n37_o when n39_o = '0' else n38_o;
  -- fsm.vhd:71:56
  n44_o <= '1' when state = "000" else '0';
  -- fsm.vhd:71:46
  n45_o <= n49_o when n44_o = '0' else "00000000";
  -- fsm.vhd:72:56
  n48_o <= '1' when state = "001" else '0';
  -- fsm.vhd:71:60
  n49_o <= n53_o when n48_o = '0' else "00000001";
  -- fsm.vhd:73:56
  n52_o <= '1' when state = "010" else '0';
  -- fsm.vhd:72:60
  n53_o <= n57_o when n52_o = '0' else "00000010";
  -- fsm.vhd:74:56
  n56_o <= '1' when state = "011" else '0';
  -- fsm.vhd:73:60
  n57_o <= n61_o when n56_o = '0' else "00000011";
  -- fsm.vhd:75:56
  n60_o <= '1' when state = "100" else '0';
  -- fsm.vhd:74:60
  n61_o <= n65_o when n60_o = '0' else "00000100";
  -- fsm.vhd:76:56
  n64_o <= '1' when state = "101" else '0';
  -- fsm.vhd:75:60
  n65_o <= n69_o when n64_o = '0' else "00000101";
  -- fsm.vhd:77:56
  n68_o <= '1' when state = "110" else '0';
  -- fsm.vhd:76:60
  n69_o <= "00000111" when n68_o = '0' else "00000110";
end rtl;
