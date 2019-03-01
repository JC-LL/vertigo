-- Name: A timer with 2 7-segment displays
-- The program is written by Chia-Tien Dan Lo. Date: 2/28/98
-- The inputs are reset and clock.
-- The outputs are dig_sig0, dig_sig1 and sum.

library ieee;
use ieee.std_logic_1164.all;

entity ttimer is
 port(reset, clock: in bit;
  dig_sig0, dig_sig1: out bit_vector(7 downto 0);
  sum: out integer range 0 to 59);
end ttimer;

architecture flow of ttimer is
 signal s_sum: integer range 0 to 59;
 signal s_clock: bit;
begin
 time: process(clock, reset)
  variable cnt: integer :=0;
 begin
  if reset = '0' then
   cnt := 0;
  elsif clock'event and clock = '1' then
   if cnt = 25175000 then
    s_clock <= not s_clock;
    cnt := 0;
   else
    cnt := cnt +1;
   end if;
  end if;
 end process;

 time_move: process(reset, s_clock)
 begin
  if reset = '0' then
   s_sum <= 0;
  elsif s_clock'event and s_clock = '1' then
   if s_sum = 59 then
    s_sum <= 0;
   else
    s_sum <= s_sum +1;
   end if;
  end if;
 end process;
 sum <= s_sum;
 
 with s_sum select
 dig_sig1 <= "10000001" when 0,
    "11001111"  when 1,
    "10010010"  when 2,
    "10000110" when 3,
    "11001100" when 4,
    "10100100" when 5,
    "10100000" when 6,
    "10001101" when 7,
    "10000000" when 8,
    "10000100" when 9,
    "10000001" when 10,
    "11001111"  when 11,
    "10010010"  when 12,
    "10000110" when 13,
    "11001100" when 14,
    "10100100" when 15,
    "10100000" when 16,
    "10001101" when 17,
    "10000000" when 18,
    "10000100" when 19,
    "10000001" when 20,
    "11001111"  when 21,
    "10010010"  when 22,
    "10000110" when 23,
    "11001100" when 24,
    "10100100" when 25,
    "10100000" when 26,
    "10001101" when 27,
    "10000000" when 28,
    "10000100" when 29,
    "10000001" when 30,
    "11001111"  when 31,
    "10010010"  when 32,
    "10000110" when 33,
    "11001100" when 34,
    "10100100" when 35,
    "10100000" when 36,
    "10001101" when 37,
    "10000000" when 38,
    "10000100" when 39,
    "10000001" when 40,
    "11001111"  when 41,
    "10010010"  when 42,
    "10000110" when 43,
    "11001100" when 44,
    "10100100" when 45,
    "10100000" when 46,
    "10001101" when 47,
    "10000000" when 48,
    "10000100" when 49,
    "10000001" when 50,
    "11001111"  when 51,
    "10010010"  when 52,
    "10000110" when 53,
    "11001100" when 54,
    "10100100" when 55,
    "10100000" when 56,
    "10001101" when 57,
    "10000000" when 58,
    "10000100" when 59;

 

 dig_sig0 <= "10000001" when s_sum >= 0  and s_sum <= 9  else
    "11001111"  when s_sum >=10  and s_sum <= 19 else
    "10010010"  when s_sum >=20  and s_sum <= 29 else
    "10000110" when s_sum >=30  and s_sum <= 39 else
    "11001100" when s_sum >=40  and s_sum <= 49 else
    "10100100" ;
 
end flow; 
