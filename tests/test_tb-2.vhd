-- Test Bench code for ALU
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.ALU_package.all;

entity ALU_TB is			-- entity declaration
end ALU_TB;

architecture TB of ALU_TB is

    component ALU
	    port(
				A:	in std_logic_vector(1 downto 0);
				B:	in std_logic_vector(1 downto 0);
				Sel:	in std_logic_vector(1 downto 0);
				Res:	out std_logic_vector(1 downto 0)
	    );
    end component;

    signal A, B, Res: std_logic_vector(1 downto 0):="00";
    signal Sel: std_logic_vector(1 downto 0);

begin

    U_ALU: ALU port map (A, B, Sel, Res);

    process
    begin

	sig_A <= "10";
	sig_B <= "01";

	sig_Sel <= "00";			-- case 1: Addition
	wait for 1 ns;
	load_data(A, B, Sel);
	wait for 1 ns;
	sig_Res <= Res;
	wait for INTERVAL;
	check_data(Sel);

	sig_Sel <= "01";			-- case 2: subtraction
	wait for 1 ns;
	load_data(A, B, Sel);
	wait for 1 ns;
	sig_Res <= Res;
	wait for INTERVAL;
	check_data(Sel);

	sig_Sel <= "10";			-- case 3: AND operation
	wait for 1 ns;
	load_data(A, B, Sel);
	wait for 1 ns;
	sig_Res <= Res;
	wait for INTERVAL;
	check_data(Sel);

	sig_Sel <= "11";			-- case 4: OR operation
	wait for 1 ns;
	load_data(A, B, Sel);
	wait for 1 ns;
	sig_Res <= Res;
	wait for INTERVAL;
	check_data(Sel);
	wait;


    end process;

end TB;
