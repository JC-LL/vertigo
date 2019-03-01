entity ttimer is
end ttimer;

architecture flow of ttimer is
  signal  sig,sig1,sig2 : boolean;
  signal s_sum : integer;
begin
  sig <= sig1 and sig2;
  sig <= s_sum >= 0  and s_sum <= 9;
end flow; 
