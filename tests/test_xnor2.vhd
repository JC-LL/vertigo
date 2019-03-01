entity XNOR2 is

     port (A, B: in std_logic;

           Z: out std_logic);

     end XNOR2;



architecture behavioral_xnor of XNOR2 is

     -- signal declaration (of internal signals X, Y)

     signal X, Y: std_logic;

begin
  X <= A and B;

  Y <= (not A) and (not B);

  Z <= X or Y;

End behavioral_xnor;
