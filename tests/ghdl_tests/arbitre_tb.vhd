--------------------------------------------------------------------------------
-- this file was generated automatically by Vertigo Ruby utility
-- date : (d/m/y h:m) 15/02/2023 14:26
-- author : Jean-Christophe Le Lann - 2014
--------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity arbitre_tb is
end entity;
 
architecture bhv of arbitre_tb is
  constant HALF_PERIOD : time :=5 ns;
 
  signal clk : std_logic := '0';
  signal reset_n : std_logic := '0';
 
  signal running : boolean := true;
 
  procedure wait_cycles(n : natural) is 
  begin
    for i in 0 to n-1 loop
      wait until rising_edge(clk);
    end loop;
  end procedure;
 
  procedure toggle(signal s : inout std_logic) is
  begin
    wait until rising_edge(clk);
    s <=not(s);
    wait until rising_edge(clk);
    s <=not(s);
  end procedure;
 
  signal outputs : std_logic_vector(1 downto 0);
begin
  --------------------------------------------------------------------------------
  -- clock and reset
  --------------------------------------------------------------------------------
  reset_n <= '0','1' after 123 ns;
   
  clk <= not(clk) after HALF_PERIOD when running else clk;
  --------------------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------------------
  dut : entity work.arbitre(arch)
    port map (
      clk     => clk    ,
      reset_n => reset_n,
      outputs => outputs);
  --------------------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------------------
  stim : process
  begin
    report "running testbench for arbitre(arch)";
    report "waiting for asynchronous reset";
    wait until reset_n='1';
    wait_cycles(10);
    wait_cycles(200);
    report "end of simulation";
    running <= false;
    wait;
  end process;
end bhv;
