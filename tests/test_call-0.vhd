architecture BEH of FIR_filter is
begin

  MULT8(j) <= signed(REG1(j)); -- * signed(COEF(j));

end BEH;
