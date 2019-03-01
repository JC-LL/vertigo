

architecture flow of ttimer is
 
begin

 dig_sig0 <= "10000001" when s_sum >= 0  and s_sum <= 9  else "11001111";
 
end flow; 
