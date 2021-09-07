library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rca_vhdl_93 of adder is
  signal co : std_logic_vector(N-1 downto 0);
begin

  gen_loop: for i in 0 to N-1 generate

    bit0 : if i=0 generate
      fa_0: entity work.fa(arch)
      port map(
        a  => a(0),
        b  => b(0),
        ci => '0',
        s  => sum(0),
        co => co(0)
      );
    end generate bit0;

    other_bits : if i >0  generate
      fa_i : entity work.fa(arch)
      port map(
        a  => a(i),
        b  => b(i),
        ci => co(i-1),
        s  => sum(i),
        co => co(i)
      );
    end generate other_bits;

  end generate gen_loop;

  carry <= co(N-1);

end architecture;
