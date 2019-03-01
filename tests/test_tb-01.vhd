

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity DECODER_TB is
end DECODER_TB;

architecture TB of DECODER_TB is

  signal T_I : std_logic_vector(1 downto 0) := "00";
  signal T_O : std_logic_vector(3 downto 0);
  
  
  component decoder port(
    I : in  std_logic_vector(1 downto 0);
    O : out std_logic_vector(3 downto 0)
    );
  end component;

begin

  U_DECODER : DECODER port map (T_I, T_O);

  process
    variable err_cnt : integer := 0;
  begin

    wait for 10 ns;   
    T_I <= "00";
    wait for 1 ns;
    assert (T_O="0001") report "Error Case 0"  severity error;
    if (T_O/="0001") then 
        err_cnt := err_cnt + 1;
    end if;


    wait for 10 ns;
    T_I <= "01";                                                                                
    wait for 1 ns;
    assert (T_O="0010") report "Error Case 1" 
    severity error;
    if (T_O/="0010") then
        err_cnt := err_cnt + 1;
    end if;


    wait for 10 ns;
    T_I <= "10";                                                                                 
    wait for 1 ns;
    assert (T_O="0100") report "Error Case 2" 
    severity error;
    if (T_O/="0100") then
        err_cnt := err_cnt + 1;
    end if;


    wait for 10 ns;
    T_I <= "11";                                                                                
    wait for 1 ns;
    assert (T_O="1000") report "Error Case 3" 
    severity error;
    if (T_O/="1000") then
        err_cnt := err_cnt + 1;
    end if;


    wait for 10 ns;
    T_I <= "UU";              


    if (err_cnt=0) then                       
        assert false 
        report "Testbench of Adder completed successfully!" 
        severity note; 
    else 
        assert true 
        report "Something wrong, try again" 
        severity error; 
    end if; 

    wait;

  end process;

end TB;


