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
      dump_ast if options[:dump_ast]
      return true if ast
    end

    def parse filename
      @ast=Parser.new(options).parse filename
    end

    def dump_ast
      pp @ast
    end
  end
end
