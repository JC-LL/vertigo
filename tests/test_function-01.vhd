
package body lfsr_pkg is

    function many_to_one_fb (DATA, TAPS :std_logic_vector) return std_logic_vector is
        variable xor_taps :std_logic;
        variable all_0s   :std_logic;
        variable feedback :std_logic;
    begin

        -- Validate if lfsr = to zero (Prohibit Value)
        if (DATA(DATA'length-2 downto 0) = 0) then
            all_0s := '1';
        else
            all_0s := '0';
        end if;

        xor_taps := '0';
        for idx in 0 to (TAPS'length-1) loop
            if (TAPS(idx) = '1') then
                xor_taps := xor_taps xor DATA(idx);
            end if;
        end loop;

        feedback := xor_taps xor all_0s;

        return DATA((DATA'length-2) downto 0) & feedback;
    end function;

    
end package body;


    
