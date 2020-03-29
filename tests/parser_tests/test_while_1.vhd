

architecture test_while of while_tester is

begin  -- test_while

  Clk_1 : process (Clock)
  begin
    L1 : loop
      Clock <= not Clock after 5 ns;
    end loop L1;
  end process Clk_1;

  process
    begin
    L2 : loop
      A := A+1;
      exit L2 when A > 10;
    end loop L2;
  end process;

  Shift_3 : process (Input_X)
    variable i : positive := 1;
  begin
    L3 : while i <= 8 loop
      Output_X(i) <= Input_X(i+8) after 5 ns;
      i           := i + 1;
    end loop L3;
  end process Shift_3;

  Shift_4 : process (Input_X)
  begin
    L4 : for count_value in 1 to 8 loop
      Output_X(count_value) <= Input_X(count_value + 8) after 5 ns;
    end loop L4;
  end process Shift_4;

end test_while;
