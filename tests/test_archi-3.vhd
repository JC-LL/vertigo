-- Troisième architecture concurrente décrivant un mux :
ARCHITECTURE mux_4_vers_1 OF porte_4_vers_1 IS
 
BEGIN
  s <= a  WHEN adr = "00" ELSE
       b  WHEN adr = "01" ELSE
       c  WHEN adr = "10" ELSE
       d;
END mux_4_vers_1;
