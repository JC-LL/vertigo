library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultSeq is

  port (
    clk, reset_n : in  std_logic;
    start        : in  std_logic;
    req_a        : in  std_logic;
    req_b        : in  std_logic;
    a, b         : in  std_logic_vector(3 downto 0);
    ready        : out std_logic;
    res          : out std_logic_vector(7 downto 0);
    state_o      : out std_logic_vector(3 downto 0)
    );
end MultSeq;

-------------------------------------------------------------------------------
-- architecture LOGIC : VHDL restreint a l'UV 1.5
-------------------------------------------------------------------------------
architecture logic of MultSeq is

  signal state, next_state : std_logic_vector(3 downto 0);

  -- assignation des encodages des etats (encodage one-hot)
  constant IDLE   : std_logic_vector(3 downto 0) := "0001";
  constant WAIT_A : std_logic_vector(3 downto 0) := "0010";
  constant WAIT_B : std_logic_vector(3 downto 0) := "0100";
  constant MULT   : std_logic_vector(3 downto 0) := "1000";

  -- signaux de controle
  signal init  : std_logic;
  signal chRa  : std_logic;
  signal chRb  : std_logic;
  signal shift : std_logic;
  signal add   : std_logic;

  -- registre du datapath
  signal accu_reg, accu_reg_comb : unsigned(7 downto 0);
  signal reg_b, reg_b_comb       : unsigned(7 downto 0);
  signal reg_a, reg_a_comb       : unsigned(3 downto 0);

  -- signaux de status : datapath => controleur
  signal stop  : std_logic;
  signal lsb_a : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Controleur
  -----------------------------------------------------------------------------
  bascules_etat : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= IDLE;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;

  -- logique combinatoire d'etat suivant
  next_state(0) <= (state(3) and stop) or (state(0) and not(start));
  next_state(1) <= (state(0) and start) or (state(1) and not(req_a));
  next_state(2) <= (state(1) and req_a) or (state(2) and not(req_b));
  next_state(3) <= (state(2) and req_b) or (state(3) and not(stop));

  -- signaux controleur --> datapath
  shift <= state(3);
  add   <= state(3) and lsb_a;
  chrA  <= state(1) and req_a;
  init  <= state(1) and req_a;
  chrB  <= state(2) and req_b;

  -- signal vers l'exterieur (fin traitement)
  ready <= state(0);
  state_o <= state;
  -------------------------------------------------------------------------------
  --datatpath
  -----------------------------------------------------------------------------
  B_reg_proc : process (clk, reset_n)
  begin
    if reset_n = '0' then
      reg_b <= "00000000";
    elsif rising_edge(clk) then
      reg_b <= reg_b_comb;
    end if;
  end process;

  reg_b_comb <= unsigned("0000" & b) when chRb = '1' else
                reg_b(6 downto 0) & '0' when shift = '1' else
                reg_b;
  -----------------------------------------------------------------------------
  a_reg_proc : process (clk, reset_n)
  begin
    if reset_n = '0' then
      reg_a <= "0000";
    elsif rising_edge(clk) then
      reg_a <= reg_a_comb;
    end if;
  end process;

  reg_a_comb <= unsigned(a) when chRa = '1' else
                '0' & reg_a(3 downto 1) when shift = '1' else
                reg_a;
  -----------------------------------------------------------------------------
  ACCU : process (clk, reset_n)
    variable tmp : unsigned(3 downto 0);
  begin
    if reset_n = '0' then
      accu_reg <= to_unsigned(0, 8);
    elsif rising_edge(clk) then
      accu_reg <= accu_reg_comb;
    end if;
  end process;

  accu_reg_comb <= to_unsigned(0, 8) when init = '1' else
                   accu_reg + reg_b when add = '1' else
                   accu_reg;
  -----------------------------------------------------------------------------
  res <= std_logic_vector(accu_reg);

  lsb_a <= reg_a(0);
  stop  <= not(reg_a(3) or reg_a(2) or reg_a(1) or reg_a(0));

end logic;

-------------------------------------------------------------------------------
-- architecture beneficiant d'un codage VHDL plus evolue : RTL
-------------------------------------------------------------------------------
architecture RTL of MultSeq is

  type   state_type is (IDLE, waitA, waitB, Mult);
  signal state, next_state : state_type;

  type control_type is record
    init  : std_logic;
    chRa  : std_logic;
    chRb  : std_logic;
    shift : std_logic;
    add   : std_logic;
  end record;

  constant NO_CONTROL : control_type := ('0', '0', '0', '0', '0');
  signal   control    : control_type;

  type status_type is record
    lsb  : std_logic;
    stop : std_logic;
  end record;

  signal status : status_type;

  signal accu_reg : unsigned(7 downto 0);
  signal b_Reg    : unsigned(7 downto 0);
  signal a_Reg    : unsigned(3 downto 0);

begin

  tick : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= IDLE;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;

  controler_next_state : process (req_a, req_b, start, state, status)
    variable state_v   : state_type;
    variable control_v : control_type;
  begin
    state_v   := state;
    control_v := NO_CONTROL;
    ready     <= '0';

    case state_v is

      when IDLE =>
        ready <= '1';
        if start = '1' then
          state_v := waitA;
        end if;

      when waitA =>
        if req_a = '1' then
          state_v        := waitB;
          control_v.chRa := '1';
          control_v.init := '1';
        end if;

      when waitB =>
        if req_b = '1' then
          state_v        := Mult;
          control_v.chRb := '1';
        end if;

      when Mult =>
        if status.stop = '1' then
          state_v := IDLE;
        else
          control_v.shift := '1';
          if status.lsb = '1' then
            control_v.add := '1';
          end if;
        end if;

      when others => null;
    end case;
    control    <= control_v;
    next_state <= state_v;
  end process;

  -------------------------------------------------------------------------------
  --datatpath elements
  -----------------------------------------------------------------------------

  B_reg_proc : process (clk, reset_n)
  begin
    if reset_n = '0' then
      B_Reg <= "00000000";
    elsif rising_edge(clk) then
      if control.chRb = '1' then
        B_Reg <= unsigned("0000" & a);
      elsif control.shift = '1' then
        B_Reg <= B_Reg(6 downto 0) & '0';
      end if;
    end if;
  end process;

  a_reg_proc : process (clk, reset_n)
  begin
    if reset_n = '0' then
      a_Reg <= "0000";
    elsif rising_edge(clk) then
      if control.chRb = '1' then
        a_Reg <= unsigned(b);
      elsif control.shift = '1' then
        a_Reg <= '0' & a_Reg(3 downto 1);
      end if;
    end if;
  end process;

  aCCU : process (clk, reset_n)
    variable tmp : unsigned(3 downto 0);
  begin
    if reset_n = '0' then
      accu_reg <= to_unsigned(0, 8);
    elsif rising_edge(clk) then
      if control.init = '1' then
        accu_reg <= to_unsigned(0, 8);
      elsif control.add = '1' then
        accu_reg <= accu_reg + b_Reg;
      end if;
    end if;
  end process;

  res <= std_logic_vector(accu_reg);

  status.lsb  <= a_reg(0);
  status.stop <= not(a_Reg(3) or a_Reg(2) or a_Reg(1) or a_Reg(0));

end RTL;
