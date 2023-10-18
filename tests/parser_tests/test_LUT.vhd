-- ghdl -a [nom].vhd
-- vertigo --gen_tb [nom].vhd
-- ghdl -a [nom_tb].vhd
-- ghdl -e [nom_tb]
-- ghdl -r [nom_tb]
-- ghdl -r [nom_tb] --wave=[nom_wave].ghw
-- gtkwave [nom].ghw

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LUT is
  port (
    clk  : in std_logic;
    rst  : in std_logic;
    push : in std_logic;
    a    : in std_logic;
    b    : in std_logic;
    bitstream : in std_logic;
    f    : out std_logic

  );
end LUT;

architecture arch of LUT is
	signal Q : std_logic_vector (3 downto 0);
	signal T : std_logic_vector (1 downto 0);
begin

process(clk, rst) is
	begin

		if rst = '0' then
			Q(0) <= '0';
			Q(1) <= '0';
			Q(2) <= '0';
			Q(3) <= '0';

		elsif rising_edge(clk) then
			if push = '1' then
				Q(0) <= bitstream;
				Q(1) <= Q(0);
				Q(2) <= Q(1);
				Q(3) <= Q(2);
			end if;
		end if;
	end process;

process (a, b) is
	begin
		t(0) <= a;
		t(1) <= b;
		case t is
			when "00"   => f <= Q(0);
			when "01"   => f <= Q(1);
			when "10"   => f <= Q(2);
			when "11"   => f <= Q(3);
			when others => f <= Q(0);
		end case;
	end process;
end arch;
