

architecture RTL of DE2 is
 
  function binTo7Seg(bin : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable res : std_logic_vector(6 downto 0);
  begin
    res := "0000000";
    case bin is
      when "0000" => res := "0111111";  --0
      when "0001" => res := "0000110";  --1
      when "0010" => res := "1011011";  --2
      when "0011" => res := "1001111";  --3
      when "0100" => res := "1100110";  --4
      when "0101" => res := "1101101";  --5
      when "0110" => res := "1111101";  --6
      when "0111" => res := "0000111";  --7
      when "1000" => res := "1111111";  --8
      when "1001" => res := "1101111";  --9
      when "1010" => res := "1110111";  --A
      when "1011" => res := "1111100";  --b
      when "1100" => res := "0111001";  --C
      when "1101" => res := "1011110";  --d
      when "1110" => res := "1111001";  --E
      when "1111" => res := "1110001";  --F
      when others => null;
    end case;
    return res;
  end binTo7Seg;

  function one_hot_to_dec (bin : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable res : std_logic_vector(3 downto 0);
  begin
    res := "0000";
    for i in bin'range loop
      if bin(i) = '1' then
        return std_logic_vector(to_unsigned(i, 4));
      end if;
    end loop;
    return res;
  end one_hot_to_dec;


begin  
end RTL;
