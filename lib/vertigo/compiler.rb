require_relative 'ast'
require_relative 'parser'
require_relative 'version'
require_relative 'pretty_printer'

module Vertigo

  class Compiler

    attr_accessor :options
    attr_accessor :ast

    def initialize options={}
      @options=options
    end

    def compile filename
      begin
        puts "=> analyzing VHDL file : #{filename}" unless options[:mute]
        @basename=File.basename(filename,File.extname(filename))
        ast=parse(filename)
        puts "=> parsed successfully. Good" unless options[:mute]
        dump_ast if options[:dump_ast]
        pretty_print if options[:pp] or options[:pp_to_file]
        return true
      rescue Exception => e
        puts e.backtrace unless options[:mute]
        puts e unless options[:mute]
        raise
      end
    end

    def parse filename
      @ast=Parser.new(options).parse filename
    end

    def dump_ast
      pp @ast
    end

    def pretty_print
      puts "=> pretty printing" unless options[:mute]
      begin
        code=PrettyPrinter.new.print(ast)
        file=code.save_as "#{@basename}_pp.vhd"
        puts "   - saved as #{file}" unless options[:mute]
        puts code.finalize if options[:pp]
      rescue Exception => e
        puts e.backtrace if options[:pp]
        puts e if options[:pp]
        raise "pp error"
      end
    end
  end
end
