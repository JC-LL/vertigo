library IEEE;
use IEEE.std_logic_1164.all;

entity dff is
   port (d   : in std_logic;
      preset : in std_logic;
      clear  : in std_logic;
      clk    : in std_logic;
      q      : out std_logic);
end dff;

architecture bhv_dff of dff is
begin
    process(clk, clear, preset)
    begin
     if clear = '0' then
           q <= '0';
     elsif preset = '1' then
          q <= '1';
     elsif clk'event and clk='1' then
        q <= d;
     end if;
   end process;
end bhv_dff;
