library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity fsm is
  port (
    reset_n  : in std_logic;
    clk      : in std_logic;
    switches : in std_logic_vector(7 downto 0);
    leds     : out std_logic_vector(7 downto 0);
    o1,o2    : out std_logic;
    o3       : out unsigned(3 downto 0)
  );
end entity;

architecture arch of fsm is
  type state_t is (S0,S1,S2,S3,S4,S5,S6,S7);
  signal state,state_c : state_t;

  signal c3 : unsigned(3 downto 0);
begin
  tick :process(reset_n,clk)
  begin
    if reset_n='0' then
      state <= S0;
    elsif rising_edge(clk) then
      state <= state_c;
    end if;
  end process;

  next_state_logic:process(switches)
  variable state_v : state_t;
  begin
    state_v:= state;
    o1 <= '0';
    o2 <= '1';
    case state_v is
      when S0 =>
        if switches(0)='1' then
          state_v := S1;
        end if;
      when S1 =>
        if switches(1)='1' then
          state_v := S2;
        end if;
      when S2 =>
        if switches(2)='1' then
          state_v := S3;
        end if;
      when S3 =>
        if switches(3)='1' then
          state_v := S4;
        end if;
      when S4 =>
        if switches(4)='1' then
          state_v := S5;
        end if;
      when S5 =>
        if switches(5)='1' then
          state_v := S6;
          o1 <= '1';
        end if;
      when S6 =>
        if switches(6)='1' then
          state_v := S7;
          o2 <= '1';
        end if;
      when S7 =>
        if switches(7)='1' then
          state_v := S0;
        end if;
      when others =>
        null;
    end case;
    state_c <= state_v;
  end process;

  -- single output
  leds <= std_logic_vector(to_unsigned(0,8)) when state=S0 else
          std_logic_vector(to_unsigned(1,8)) when state=S1 else
          std_logic_vector(to_unsigned(2,8)) when state=S2 else
          std_logic_vector(to_unsigned(3,8)) when state=S3 else
          std_logic_vector(to_unsigned(4,8)) when state=S4 else
          std_logic_vector(to_unsigned(5,8)) when state=S5 else
          std_logic_vector(to_unsigned(6,8)) when state=S6 else
          std_logic_vector(to_unsigned(7,8));

  process(reset_n,clk)
  begin
    if reset_n='0' then
      c3 <= to_unsigned(0,4);
    elsif rising_edge(clk) then
      c3 <= c3 + 1;
    end if;
  end process;
  o3 <= c3;

end architecture;
