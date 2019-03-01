-- Première architecture concurrente décrivant un mux :
architecture mux_4_vers_1 of logique_4_vers_1 is

begin
  s <= a;
  s <= (a and not adr(1) and not adr(0))
       or (b and not adr(1) and adr(0))
       or (c and adr(1) and not adr(0))
       or (d and adr(1) and adr(0));
end mux_4_vers_1;
