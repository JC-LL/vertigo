-- Première architecture concurrente décrivant un mux :
 ARCHITECTURE mux_4_vers_1 OF logique_4_vers_1 IS
 
 BEGIN
   s <=a;
   --s <= ( a AND NOT adr(1) AND NOT adr(0) )
   --      OR ( b AND NOT adr(1) AND     adr(0) )
   --      OR ( c AND     adr(1) AND NOT adr(0) )
   --      OR ( d AND     adr(1) AND     adr(0) );  
 END mux_4_vers_1;
