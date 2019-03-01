library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.accelerator_pkg.all;

architecture test of aggregate_2 is

  -- problem with parent before "others"
  constant t : MyRec := ( (others => '1'), (others => '0'));

begin
end rtl;
