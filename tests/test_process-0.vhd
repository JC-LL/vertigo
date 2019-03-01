architecture test of titi is

begin  -- test 

  process
  begin
    DATA <= to_unsigned(i, 8);
    -- now raise ACK for clock period
    ACK <= '1';
    ACK <= '0';
    -- and so on...
  end process;

end test;
