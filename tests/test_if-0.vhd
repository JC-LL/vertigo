-- Architecture séquentielle pour une bascule D :
ARCHITECTURE comport OF bascule_d IS
 
BEGIN
 
  bascule : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      q <= '0';
    ELSE
      IF clk'event AND clk = '1' THEN        -- Moins bien que : IF rising_edge(clk) THEN 
        q <= d;
      END IF;
    END IF;
  END process bascule;
 
END comport;
