

architecture flow of ttimer is
 
begin

 
 with s_sum select
 dig_sig1 <= "10000001" when 0,
    "11001111"  when 1,
    "10010010"  when 2,
    "10000110" when 3,
    "10000100" when 59;

 

 dig_sig0 <= "10000001" when s_sum >= 0  and s_sum <= 9  else
    "11001111"  when s_sum >=10  and s_sum <= 19 else
    "10010010"  when s_sum >=20  and s_sum <= 29 else
    "10000110" when s_sum >=30  and s_sum <= 39 else
    "11001100" when s_sum >=40  and s_sum <= 49 else
    "10100100" ;
 
end flow; 
