library ieee;
use ieee.std_logic_1164.all;

package lfsr_pkg is
  function f (a : std_logic_vector) return boolean;
end package;


package body lfsr_pkg is

  function f (a : std_logic_vector) return boolean is
    variable u : std_logic_vector(a'length-2 downto 0);
  begin
    u := a(a'length-2 downto 0);
    return false;
  end function;

  
end package body;



