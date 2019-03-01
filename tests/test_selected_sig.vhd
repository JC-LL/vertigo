-- Deuxième architecture concurrente décrivant un mux :
ARCHITECTURE mux_4_vers_1 OF porte_4_vers_1 IS
 
BEGIN

  WITH adr SELECT
    s <=  a  WHEN "00",
          b  WHEN "01",
          c  WHEN "10",
          d  WHEN others;

END mux_4_vers_1;
