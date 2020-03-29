library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (N : natural := 8);
  port(
    reset_n : in std_logic;
    clk : in std_logic;
    inc : in std_logic;
    dec : in std_logic;
    value : out signed(N-1 downto 0)
  );
end entity;

architecture rtl of counter is
  signal value_s : signed(N-1 downto 0);
begin

  process(reset_n,clk)
  begin
    if reset_n='0' then
       value_s <= to_signed(0,N);
    elsif rising_edge(clk) then
      if inc='1' then
        value_s <= value_s + 1;
      elsif dec='1' then
        value_s <= value_s - 1;
      end if;
    end if;
  end process;

  value <= value_s;

end rtl;
