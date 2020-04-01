library ieee,std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accelerator is
  port(
    reset_n : in std_logic;
    clk     : in std_logic;
    a1      : in std_logic_vector(31 downto 0);
    f1      : out std_logic_vector(31 downto 0)
  );
end entity accelerator;

architecture rtl of accelerator is
  signal a,b,c : std_logic;
  signal s : integer;
  signal d,e,f: std_logic_vector(31 downto 0);
begin

  c <= '0','1' after 15 ns;

  a <= b;

  s <= 1 when a='1' else
       2 when a='0' else
       3;

  -- absurd code
  label_1:process(s,reset_n,clk)
  begin

    if s > 32 then
      s <= 1;
    end if;

    if reset_n='0' then
      s <= 2;
    elsif rising_edge(clk) then
      s <= 1;
    end if;

    wait;
  end process;

end rtl;
