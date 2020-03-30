library ieee,std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of accelerator is

begin

  s <= a;
  s <= 1 when a>1 else
       2 when a>2 else
       3;
       
  label_1:process
  begin
    wait;
  end process;

end rtl;
