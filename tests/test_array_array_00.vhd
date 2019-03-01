library ieee;
use ieee.std_logic_1164.all;

architecture test_var of test is


begin  -- test_var

  test : process
    type TestIt is array(natural range <>) of boolean;
    type     Mem is array (natural range <>, natural range <>) of std_logic;
    variable TempCond : boolean              := true;
    variable RAM2     : Mem (0 to 7, 0 to 7) :=
      (('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'),
       ('0', '0', '0', '0', '0', '0', '0', '0'));
  begin  -- process test
  end process test;

end test_var;
