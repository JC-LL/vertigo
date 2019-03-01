architecture BEH of FIR_filter is
begin

  MULT0(j) <= signed(REG0(j)) * signed(COEF(j));

end BEH;
