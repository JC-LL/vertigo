library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbitre is
port(
	clk : in std_logic;
	reset_n : in std_logic;
	r : std_logic_vector(1 downto 0);
	outputs : out std_logic_vector(1 downto 0)
	);
end arbitre;

architecture arch of arbitre is
	type etat is (A, B, C, D);
	signal state, next_state : etat;
	begin
		p0 : process(clk, reset_n)
			begin
				if reset_n = '0' then
					state <= A;
				elsif rising_edge(clk) then
					state <= next_state;
				end if;
		end process;
			
		p1 : process(reset_n, r)
			begin
				next_state <= state;
				case state is
					when A =>
						if r = "10" or r = "11" then
							state <= C;
						elsif r = "01" then
							state <= D;
						elsif r = "00" then
							state <= state;
						end if;
					when B =>
						if r = "01" or r = "11" then
							state <= D;
						elsif r = "10" then
							state <= C;
						elsif r = "00" then
							state <= state;
						end if;
					when C =>
						if r = "01" then
							state <= D;
						elsif r = "00" then
							state <= B;
						elsif r = "10" or r = "11" then
							state <= state;
						end if;
					when D =>
						if r = "10" then
							state <= C;
						elsif r = "00" then
							state <= A;
						elsif r = "01" or r = "11" then
							state <= state;
						end if;
				end case;
		end process;
		
		p3 : process(state)
			begin
				if state = A then
					outputs <= "00";
				elsif state = B then
					outputs <= "00";
				elsif state = C then
					outputs <= "10";
				elsif state = D then
					outputs <= "01";
				end if;
		end process;
end arch;
					
