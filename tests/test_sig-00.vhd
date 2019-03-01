entity toto is
  
  port (
    a, b, c : in  boolean;
    f       : out boolean);
end toto;

architecture test of toto is
  signal s : boolean;
begin  -- test

  s <= a and b and c;

end test;
