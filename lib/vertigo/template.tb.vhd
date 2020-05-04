-----------------------------------------------------------------
-- This file was generated automatically by Vertigo Ruby utility
-- date : <%=Time.now.strftime("(d/m/y) %d/%m/%Y %H:%M")%>
-- Author : Jean-Christophe Le Lann - 2014
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
<%@supplemental_libs_h.each do |lib,packages|%>
library <%=lib%>;
<%packages.each do |package|%>
use <%=lib%>.<%=package%>.all;
<%end%>
<%end%>

entity <%=@tb_name%> is
end entity;

architecture bhv of <%=@tb_name%> is

  constant HALF_PERIOD : time := 5 ns;

  signal <%=clk.name.str%> : std_logic := '0';
  signal <%=rst.name.str%> : std_logic := '0';

  signal running : boolean   := true;

  procedure wait_cycles(n : natural) is
   begin
     for i in 1 to n loop
       wait until rising_edge(clk);
     end loop;
   end procedure;

<%=@entity.ports.collect do |port|
  "  signal #{port.name.str.ljust(@max_length_str)} : #{port.type.str}" if not @excluded.include?(port)
  end.compact.join(";\n")%>;

begin
  -------------------------------------------------------------------
  -- clock and reset
  -------------------------------------------------------------------
  reset_n <= '0','1' after 666 ns;

  clk <= not(clk) after HALF_PERIOD when running else clk;

  --------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------
  dut : entity work.<%=@entity.name.str%>(<%=@arch.name.str%>)
        <%=@generics%>
        port map ( <%map=@entity.ports.collect do |port| "\t  #{port.name.str} => #{port.name.str}" end%>
<%=map.join(",\n")%>
        );

  --------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------
  stim : process
   begin
     report "running testbench for <%=@entity.name.str%>(<%=@arch.name.str%>)";
     report "waiting for asynchronous reset";
     wait until reset_n='1';
     wait_cycles(100);
     report "applying stimuli...";
     wait_cycles(100);
     report "end of simulation";
     running <=false;
     wait;
   end process;

end bhv;
