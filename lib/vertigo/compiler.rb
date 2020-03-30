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
      puts "analyzing VHDL file : #{filename}" unless options[:mute]
      ast=parse(filename)
      return true if ast
    end

    def parse filename
      @ast=Parser.new(options).parse filename
    end
  end
end
