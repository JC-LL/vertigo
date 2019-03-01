library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;               -- for the unsigned type

entity COUNTER is
  generic (
    WIDTH : in natural := 32);
  port (
    RST  : in  std_logic;
    CLK  : in  std_logic;
    LOAD : in  std_logic;
    DATA : in  std_logic_vector(WIDTH-1 downto 0);
    Q    : out std_logic_vector(WIDTH-1 downto 0));
end entity COUNTER;

architecture RTL of COUNTER is
  signal CNT : unsigned(WIDTH-1 downto 0);
begin
  process(RST, CLK) is
  begin
    if RST = '1' then
      CNT <= (others => '0');
    elsif rising_edge(CLK) then
      if LOAD = '1' then
        CNT <= unsigned(DATA);          -- type is converted to unsigned
      else
        CNT <= CNT + 1;
      end if;
    end if;
  end process;

  Q <= std_logic_vector(CNT);  -- type is converted back to std_logic_vector
end architecture RTL;
