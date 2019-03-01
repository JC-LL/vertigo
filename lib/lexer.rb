require_relative 'generic_lexer'
require_relative 'generic_parser'

module Vertigo
  class Lexer < GenericLexer
    def initialize
      super
      ignore /\s+/

      keyword 'abs'
      keyword 'access'
      keyword 'after'
      keyword 'alias'
      keyword 'all'
      keyword 'and'
      keyword 'architecture'
      keyword 'array'
      keyword 'assert'
      keyword 'attribute'
      keyword 'begin'
      keyword 'block'
      keyword 'body'
      keyword 'buffer'
      keyword 'bus'
      keyword 'case'
      keyword 'component'
      keyword 'configuration'
      keyword 'constant'
      keyword 'disconnect'
      keyword 'downto'
      keyword 'else'
      keyword 'elsif'
      keyword 'end'
      keyword 'entity'
      keyword 'exit'
      keyword 'file'
      keyword 'for'
      keyword 'function'
      keyword 'generate'
      keyword 'generic'
      keyword 'group'
      keyword 'guarded'
      keyword 'if'
      keyword 'impure'
      keyword 'in'
      keyword 'inertial'
      keyword 'inout'
      keyword 'is'
      keyword 'label'
      keyword 'library'
      keyword 'linkage'
      keyword 'literal'
      keyword 'loop'
      keyword 'map'
      keyword 'mod'
      keyword 'nand'
      keyword 'natural'
      keyword 'integer'
      keyword 'boolean'
      keyword 'positive'
      keyword 'new'
      keyword 'next'
      keyword 'nor'
      keyword 'not'
      keyword 'null'
      keyword 'of'
      keyword 'on'
      keyword 'open'
      keyword 'or'
      keyword 'others'
      keyword 'out'
      keyword 'package'
      keyword 'port'
      keyword 'postponed'
      keyword 'procedure'
      keyword 'process'
      keyword 'pure'
      keyword 'range'
      keyword 'record'
      keyword 'register'
      keyword 'reject'
      keyword 'report'
      keyword 'return'
      keyword 'rol'
      keyword 'ror'
      keyword 'select'
      keyword 'severity'
      keyword 'signal'
      keyword 'shared'
      keyword 'sla'
      keyword 'sli'
      keyword 'sra'
      keyword 'srl'
      keyword 'subtype'
      keyword 'then'
      keyword 'to'
      keyword 'transport'
      keyword 'type'
      keyword 'unaffected'
      keyword 'units'
      keyword 'until'
      keyword 'use'
      keyword 'variable'
      keyword 'wait'
      keyword 'when'
      keyword 'while'
      keyword 'with'
      keyword 'xnor'
      keyword 'xor'

      #.............................................................
      token :comments          , /\A\-\-(.*)$/
      token :selected_name     , /\w+(\.\w+)+/ # /\S+\w+\.\w+/
      token :bit_string_literal, /(b|o|x)"[^_]\w+"/
      token :identifier        , /[a-zA-Z]\w*/
      token :string_literal    , /"[^"]*"/
      token :char_literal      , /'(\w+)'/
      token :attribute_designator , /'(\w+)/
      token :decimal_literal   , /\d+(\.\d+)?(E([+-]?)\d+)?/
      token :based_literal     , /\d+#\w+(\.\w+)?#(E[+-]?\d+)/

      token :vassign           , /\A\:\=/
      token :comma             , /\A\,/
      token :colon             , /\A\:/
      token :semicolon         , /\A\;/
      token :lparen            , /\A\(/
      token :rparen            , /\A\)/
      token :plus              , /\A\+/
      token :minus             , /\A\-/
      token :mult              , /\A\*/

      token :urange            , /\A<>/

      token :sassign           , /\A\<\=/
      token :imply             , /\A\=\>/
      token :eq                , /\A\=/
      token :ampersand         , /\A\&/
      token :neq               , /\A\/\=/
      token :gte               , /\A\>\=/
      token :gt                , /\A\>/
      token :lt                , /\A\</

      #............................................................
      token :newline     , /[\n]/
      token :space       , /[ \t\r]+/

    end #def
  end #class
end #module
