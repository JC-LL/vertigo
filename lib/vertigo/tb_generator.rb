require 'erb'

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
      entity_arch=find_entity_arch
      detecting_clk_and_reset entity_arch
      @tb_name=entity_arch.first.name.str+'_tb'
      erb=ERB.new(IO.read "#{__dir__}/template.tb.vhd")
      vhdl_tb=erb.result(binding)
      tb_filename=@tb_name+".vhd"
      File.open(tb_filename,'w'){|f| f.puts vhdl_tb}
      puts "=> generated testbench : #{tb_filename}"
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
      [@entity,@arch]
    end

    def detecting_clk_and_reset entity_arch
      puts "=> detecting clock and reset"
      entity,arch=entity_arch
      inputs=entity.ports.select{|port| port.is_a?(Input)}
      @clk = inputs.sort_by{|input| levenshtein_distance(input.name.str,"clk")}.first
      @rst = inputs.sort_by{|input| levenshtein_distance(input.name.str,"reset")}.first
      puts "\t-most probable clk   : #{@clk.name.str}"
      puts "\t-most probable reset : #{@rst.name.str}"
      @max_length_str=entity.ports.map{|port| port.name.str.size}.max
      @excluded=[@clk,@rst]
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
