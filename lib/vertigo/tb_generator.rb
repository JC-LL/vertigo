module Vertigo

  class TestBenchGenerator
    attr_accessor :ast
    attr_accessor :entity,:arch
    attr_accessor :clk,:rst
    def initialize options={}
      @options=options
      @supplemental_libs_h=options[:supplemental_libs_h]||{}
    end

    def generate_from ast
      @ast=ast
      entity_arch=find_entity_arch()
      detecting_clk_and_reset(entity_arch)
      vhdl_tb=gen_code()
      @tb_name=@entity_name+"_tb"
      tb_filename=@tb_name+".vhd"
      File.open(tb_filename,'w'){|f| f.puts vhdl_tb}
      puts "=> generated testbench : #{tb_filename}"
    end

    def line n=80
      "-"*n
    end

    def comment str
      "-- #{str}"
    end

    def gen_code
      code=Code.new
      code << gen_header
      code << "library ieee;"
      code << "use ieee.std_logic_1164.all;"
      code << "use ieee.numeric_std.all;"
      code.newline
      code << "entity #{@entity_name}_tb is"
      code << "end entity;"
      code.newline
      code << "architecture bhv of #{@entity_name}_tb is"
      code.indent=2
      code << "constant HALF_PERIOD : time :=5 ns;"
      code.newline
      code << "signal #{@clk_name} : std_logic := '0';"
      code << "signal #{@reset_name} : std_logic := '0';"
      code.newline
      code << "signal running : boolean := true;"
      code.newline
      code << "procedure wait_cycles(n : natural) is "
      code << "begin"
      code.indent=4
      code << "for i in 0 to n loop"
      code.indent=6
      code << "wait until rising_edge(#{@clk_name});"
      code.indent=4
      code << "end loop;"
      code.indent=2
      code << "end procedure;"
      @entity.ports.each do |port|
        port_name=port.name.str.ljust(@max_length_str)
        port_type=port.type.str
        code << "signal #{port_name} : #{port_type};" unless @excluded.include?(port)
      end
      code.indent=0
      code << "begin"
      code.indent=2
      code << gen_clock_and_reset
      code << instanciate_dut
      code << gen_stim_process
      code.indent=0
      code << "end bhv;"
      code.finalize
    end

    def gen_header
      code=Code.new
      code << line
      code << "-- this file was generated automatically by Vertigo Ruby utility"
      code << "-- date : (d/m/y h:m) #{Time.now.strftime("%d/%m/%Y %k:%M")}"
      code << "-- author : Jean-Christophe Le Lann - 2014"
      code << line
      code.newline
      code
    end

    def gen_clock_and_reset
      code=Code.new
      code << line
      code << comment("clock and reset")
      code << line
      code << "#{@reset_name} <= '0','1' after 666 ns;"
      code.newline
      code << "#{@clk_name} <= not(#{@clk_name}) after HALF_PERIOD when running else #{@clk_name};"
      code
    end

    def instanciate_dut
      code=Code.new
      code << line
      code << comment("Design Under Test")
      code << line
      code << "dut : entity work.#{@entity_name}(#{@arch_name})"
      code.indent=2
      code << "port map ("
      code.indent=4

      @entity.ports.each_with_index do |port,idx|
        port_name=port.name.str.ljust(@max_length_str)
        port_type=port.type.str
        if idx < @entity.ports.size-1
          code << "#{port_name} => #{port_name},"
        else
          code << "#{port_name} => #{port_name}"
        end
      end
      code.indent=2
      code << ");"
      code.indent=0
      code
    end

    def gen_stim_process
      code=Code.new
      code << line
      code << comment("sequential stimuli")
      code << line
      code << "stim : process"
      code << "begin"
      code.indent=2
      code << "report \"running testbench for #{@entity_name}(#{@arch_name})\";"
      code << "report \"waiting for asynchronous reset\";"
      code << "wait until #{@reset_name}='1';"
      code << "wait_cycles(100);"
      code << "report \"end of simulation\";"
      code << "running <= false;"
      code << "wait;"
      code.indent=0
      code << "end process;"
      code
    end

    private
    def find_entity_arch
      @entity=ast.design_units.find{|du| du.is_a? Entity}
      if @entity.nil?
        puts msg="ERROR : no entity found"
        raise msg
      end
      puts "=> found entity '#{entity.name.str}'"
      @arch=ast.design_units.find{|du| du.is_a? Architecture}
      if @arch.nil?
        puts msg="ERROR : no architecture found"
        raise msg
      end

      puts "=> found architecture '#{arch.name.str}'"
      @entity_name=@entity.name.str
      @arch_name=@arch.name.str
      [@entity,@arch]
    end

    def detecting_clk_and_reset entity_arch
      puts "=> detecting clock and reset"
      entity,arch=entity_arch
      inputs=entity.ports.select{|port| port.is_a?(Input)}
      @clk = inputs.sort_by{|input| levenshtein_distance(input.name.str,"clk")}.first
      @rst = inputs.sort_by{|input| levenshtein_distance(input.name.str,"reset_n")}.first
      puts "\t-most probable clk   : #{@clk.name.str}"
      puts "\t-most probable reset : #{@rst.name.str}"
      @max_length_str=entity.ports.map{|port| port.name.str.size}.max
      @excluded=[@clk,@rst]
      @reset_name=@rst.name.str
      @clk_name=@clk.name.str
    end

    def levenshtein_distance(s, t)
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end
  end

end
