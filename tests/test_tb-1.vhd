----------------------------------------------------------------
-- Test Bench for Tri-state Driver
-- by Weijun Zhang, 05/2001
----------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;

entity TB_tridr is
end TB_tridr;

architecture TB of TB_tridr is

    component tristate_dr is
    port(	d_in:	in std_logic_vector(7 downto 0);
		en: 	in std_logic;
		d_out:	out std_logic_vector(7 downto 0)
    );			  
    end component;

    signal T_d_in, T_d_out: std_logic_vector(7 downto 0);
    signal T_en: std_logic;
	
    begin											   

        U_UT: tristate_dr port map (T_d_in, T_en, T_d_out);
	
    process
    begin
		
	T_d_in <= "11001100";
	T_en <= '1';
	wait for 20 ns;
	assert(T_d_out = T_d_in) report "Error0 detected!"
	severity warning;
	
	T_en <= '0';
	wait for 20 ns;
	assert(T_d_out = "ZZZZZZZZ") report "Error2 detected!"
	severity error;
        
	assert(T_d_out = "ZZZZZZZZ") report "Error2 detected!"
	severity warning;
		
	T_en <= '1';
	wait for 10 ns;
		
	wait;
		
    end process;

end TB;

---------------------------------------------------------------
configuration CFG_TB of TB_tridr is
--	for TB
--	end for;
end CFG_TB;
---------------------------------------------------------------
