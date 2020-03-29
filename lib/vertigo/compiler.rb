require_relative 'ast'
require_relative 'parser'
require_relative 'version'

module Vertigo

  class Compiler

    attr_accessor :options
    attr_accessor :ast

    def initialize options={}
      @options=options
    end

    def compile filename
      puts "analyzing VHDL file : #{filename}"
      ast=parse(filename)
    end

    def parse filename
      @ast=Parser.new.parse filename
    end
  end
end
