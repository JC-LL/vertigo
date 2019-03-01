package body lfsr_pkg is

    function many_to_one_fb (DATA:std_logic_vector)
      return std_logic_vector is
    begin
	    return DATA'length;
    end function;


end package body;
