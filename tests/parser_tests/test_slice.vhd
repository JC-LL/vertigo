library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
end entity;

architecture arch of test is
  constant CST : std_logic_vector(15 downto 0) := x"1234";
  signal s1,s2 : std_logic_vector(31 downto 0);
begin

  s2 <= s1(15 downto 0) & CST;

end architecture;
