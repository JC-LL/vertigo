
package body lfsr_pkg is

  function f (a : std_logic_vector) return boolean is
    variable v : integer;
  begin
    if (a(a'length-2 downto 0) = 0) then
      all_0s := '1';
    end if;
    return a(a'length-2 downto 0) = 0;
  end function;

  
end package body;



