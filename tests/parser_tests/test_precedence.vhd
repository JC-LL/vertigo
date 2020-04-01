
entity test is
end test;

architecture bhv of test is
begin
  process
  begin
    if clk'event and clk='1' then
      report "hourra!";
    end if;
  end process;
end bhv;
