
entity test is
end test;

architecture bhv of test is
begin
  process
  begin
    report "hello" & "world" severity error;
  end process;
end bhv;
