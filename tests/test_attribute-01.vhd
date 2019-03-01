package body lfsr_pkg is

    function many_to_one_fb (DATA, TAPS :std_logic_vector) return std_logic_vector is
        variable xor_taps :std_logic;
        variable all_0s   :std_logic;
        variable feedback :std_logic;
    begin
        v1 := a;
        v2 := a(42);
        v3 := a(b(1));
        v4 := DATA'length;
	v5 := ( DATA'length );
        v6 := DATA'length - 1;
        v7 := a( 1 downto 0 );
        v8 := a( b to c );                                       
        v9  := a (DATA-2 downto 0 );
        v10 := a (b'length-2);
        v11 := a (b'length-2 downto 0);
	--v10 := (DATA(DATA'length-2 downto 0) = 0)
        

    end function;

    
end package body;


    
