library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.accelerator_pkg.all;

entity accelerator is
  port(
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    bus_addr     : in  std_logic_vector(31 downto 0);
    bus_data_p2a : in  std_logic_vector(31 downto 0);
    bus_data_a2p : out std_logic_vector(31 downto 0);
    bus_rd       : in  std_logic;
    bus_wr       : in  std_logic
    );
end accelerator;

architecture rtl of accelerator is

  type regs_t is record
    a, b, res : std_logic_vector(31 downto 0);
    ctrl      : std_logic;
    status    : std_logic_vector(1 downto 0);  --busy,done
  end record;

  constant INIT_REGS : regs_t := (
    (others => '0'),
    (others => '0'),
    (others => '0'),
    '0',
    "00"
    );

  signal ifregs : regs_t;

  type   state_t is (idle, running);
  signal state, state_c : state_t;

  type vars_t is record
    go   : std_logic;
    a, b : unsigned(31 downto 0);
    done : std_logic;
  end record;

  -- constant VARS_INIT : vars_t := (
  --   '0',
  --   to_unsigned(0, 32),
  --   to_unsigned(0, 32),
  --   '0');

  signal vars, vars_c : vars_t;

begin
  --========================================
  -- Bus interface
  --========================================
  bus_wr_proc : process(clk, reset_n)
  begin
    if reset_n = '0' then
      ifregs <= INIT_REGS;
    elsif rising_edge(clk) then
      ifregs.ctrl <= '0';                               --autoreset
      if bus_wr = '1' then
        case bus_addr is
          when ADDR_A =>
            ifregs.a <= bus_data_p2a;
          when ADDR_B =>
            ifregs.b <= bus_data_p2a;
          when ADDR_CTRL =>
            ifregs.ctrl <= bus_data_p2a(0);             --write/clear a go
          when ADDR_STATUS =>
            ifregs.status <= bus_data_p2a(1 downto 0);  --clear rdy
          when others => null;
        end case;
      elsif vars.done = '1' then
        ifregs.res       <= std_logic_vector(vars.a);  --BUG : vars.a ne passait pas
                                                       --=> FIX lexer : selected_name
        --ifregs.status(0) <= vars.done;  --BUG : (0) ne passe pas
        ifregs.status <= vars.done;  --BUG : (0) ne passe pas
      end if;
    end if;
  end process;

  bus_rd_proc : process(reset_n, clk)
  begin
    if reset_n = '0' then
      bus_data_a2p <= (others => '0');
    elsif rising_edge(clk) then
      if bus_rd = '1' then
        case bus_addr is
          when ADDR_A =>
            bus_data_a2p <= ifregs.a;
          when ADDR_B =>
            bus_data_a2p <= ifregs.b;
          when ADDR_CTRL =>
            null;
            --bus_data_a2p <= X"0000000" & "000" & ifregs.ctrl;  --write/clear a go
          when ADDR_STATUS =>
            null;
            bus_data_a2p <= X"0000000" & "00" & ifregs.status;
          when ADDR_RES =>
            bus_data_a2p <= ifregs.res;
          when others => null;
        end case;
      end if;
    end if;
  end process;

--=============================================
-- BUG
--=============================================

  reg : process(clk, reset_n)
  begin
    if reset_n = '0' then
      state <= idle;
      vars  <= VARS_INIT;
    elsif rising_edge(clk) then
      state <= state_c;
      vars  <= vars_c;
      if ifregs.ctrl = '1' then
        vars.a  <= unsigned(ifregs.a);
        vars.b  <= unsigned(ifregs.b);
        vars.go <= '1';
      end if;
    end if;
  end process;

  comb : process (state, vars)
    variable state_v : state_t;
    variable vars_v  : vars_t;
  begin
    state_v := state;
    vars_v  := vars;
    case state_v is
      when idle =>
        if vars_v.go = '1' then
          state_v   := running;
          vars_v.go := '0';
        else
          vars_v := VARS_INIT;
        end if;
      when running =>
        if vars_v.a /= vars_v.b then
          if vars_v.a > vars_v.b then
            vars_v.a := vars_v.a-vars_v.b;
          else
            vars_v.b := vars_v.b-vars_v.a;
          end if;
        else
          vars_v.done := '1';
          state_v     := idle;
        end if;
      when others => null;
    end case;
    state_c <= state_v;
    vars_c  <= vars_v;
  end process;

end rtl;
