-- Première architecture concurrente décrivant un mux :
 ARCHITECTURE mux_4_vers_1 OF logique_4_vers_1 IS
 
 BEGIN
   s2 <= a and b and not c;  
 END mux_4_vers_1;
