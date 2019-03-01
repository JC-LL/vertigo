-- Voici un exemple d'entité, décrivant les E/S utilisées
 -- par les trois exemples d'architectures purement concurrentes :
 --
 -- ATTENTION, avec certains outils de CAO, l'entité doit avoir le même nom que le fichier (logique_4_vers_1.vhd)
 ENTITY logique_4_vers_1 IS

   PORT
   (
     a   : IN STD_LOGIC;
     b   : IN STD_LOGIC;
     c   : IN STD_LOGIC;
     d   : IN STD_LOGIC;
     adr : IN STD_LOGIC_VECTOR (1 downto 0);
     s   : OUT STD_LOGIC
   );

 END logique_4_vers_1;
