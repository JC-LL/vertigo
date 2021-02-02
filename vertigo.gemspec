require_relative './lib/vertigo/version'

Gem::Specification.new do |s|
  s.name        = 'vertigo_vhdl'
  s.version     = Vertigo::VERSION
  s.date        = Time.now.strftime('%F')
  s.summary     = "VHDL parser and utilities"
  s.description = "A Ruby handwritten VHDL parser and utilities"
  s.authors     = ["Jean-Christophe Le Lann"]
  s.email       = 'jean-christophe.le_lann@ensta-bretagne.fr'
  s.files       = [
                   "bin/vertigo",
                   "lib/vertigo/ast_vertigo_rkgen.rb",
                   "lib/vertigo/ast.rb",
                   "lib/vertigo/code.rb",
                   "lib/vertigo/compiler.rb",
                   "lib/vertigo/generic_lexer.rb",
                   "lib/vertigo/generic_parser.rb",
                   "lib/vertigo/indent.rb",
                   "lib/vertigo/lexer.rb",
                   "lib/vertigo/parser.rb",
                   "lib/vertigo/pretty_printer.rb",
                   "lib/vertigo/runner.rb",
                   "lib/vertigo/token.rb",
                   "lib/vertigo/tb_generator.rb",
                   "lib/vertigo/version.rb",
                   "lib/vertigo/vertigo.rkg",
                   "lib/vertigo/visitor_vertigo_rkgen.rb",
                   "lib/vertigo.rb"
                  ]
  s.files += Dir["tests/*/*.vhd"]
  s.executables << 'vertigo'
  s.homepage    = 'http://www.github.com/JC-LL/vertigo'
  s.license       = 'GPL-2.0-only'
end
