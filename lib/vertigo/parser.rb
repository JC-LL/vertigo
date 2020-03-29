# coding: utf-8
require_relative 'generic_parser'
require_relative 'ast'
require_relative 'lexer'

module Vertigo

  class Parser < GenericParser
    attr_accessor :lexer,:tokens
    attr_accessor :basename,:filename

    def initialize
    end

    def lex filename
      unless File.exists?(filename)
        raise "ERROR : cannot find file '#{filename}'"
      end
      begin
        str=IO.read(filename).downcase
        tokens=Lexer.new.tokenize(str)
        tokens=tokens.select{|t| t.class==Token} # filters [nil,nil,nil]
        tokens.reject!{|tok| tok.is_a? [:comment,:newline,:space]}
        return tokens
      rescue Exception=>e
        puts e.backtrace
        puts e
        puts "an error occured during LEXICAL analysis. Sorry. Aborting."
        raise
      end
    end

    def parse filename
      begin
        @tokens=lex(filename)
        root=Root.new([])
        while @tokens.any?
          case showNext.kind
          when :comment
            root << acceptIt
          when :library
            root << parse_library
          when :use
            root << parse_use
          when :entity
            root << parse_entity
          when :architecture
            root << parse_architecture
          when :package
            root << parse_package
          when :configuration
            root << parse_configuration
          else
            raise "got #{showNext}"
          end
        end
      rescue Exception => e
        puts e.backtrace
        puts e
        raise
      end
      root
    end

    def consume_to token_kind
      while showNext && showNext.kind!=token_kind
        acceptIt
      end
      if showNext.nil?
        raise "cannot find token '#{token_kind}'"
      end
    end

    def parse_library
      expect :library
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expeact :ident
      end
      expect :semicolon
    end

    def parse_use
      expect :use
      expect :selected_name
      expect :semicolon
    end

    def parse_entity
      entity=Entity.new(nil,nil,[])
      expect :entity
      entity.name=expect :ident
      expect :is
      parse_generics?
      if showNext.is_a? :port
        entity.ports=parse_ports
      end
      expect :end
      maybe :ident
      maybe :entity
      expect :semicolon
      return entity
    end

    def parse_generics?
      if showNext.is_a? :generic
        generics=[]
        expect :generic
        expect :lparen
        while showNext.is_not_a? :rparen
          generics << parse_generic
          if showNext.is_a? :semicolon
            acceptIt
          end
        end
        expect :rparen
        expect :semicolon
        generics.flatten!
        return generics
      end
    end

    def parse_generic
      ids=[]
      ids << expect(:ident)
      while showNext.is_a? :comma
        acceptIt
        ids << expect(:ident)
      end
      expect :colon
      type=parse_type
      if showNext.is_a? :vassign
        acceptIt
        expr=parse_expression
      end
      ids.map{|id| Generic.new(id,type,expr)}
    end

    def parse_ports
      ports=[]
      expect :port
      expect :lparen
      while showNext.is_not_a? :rparen
        ports << parse_io
        if showNext.is_a? :semicolon
          acceptIt
        end
      end
      expect :rparen
      expect :semicolon
      ports.flatten!
      ports
    end

    def parse_io
      ids=[]
      ids << expect(:ident)
      while showNext.is_a? :comma
        acceptIt
        ids << expect(:ident)
      end
      expect :colon
      if showNext.is_a? [:in,:out,:inout]
        dir=acceptIt
        dir=dir.kind
      end
      type=parse_type
      ids.map{|id| dir==:in ? Input.new(id,type) : Output.new(id,type)}
    end

    def parse_type
      type=Identifier.new
      case showNext.kind
      when :ident
        type.tok=acceptIt
        if showNext.is_a? :lparen
          acceptIt
          parse_array_range_spec
          while showNext.is_a?(:comma) # multidim array types
            acceptIt
            parse_array_range_spec
          end
          expect :rparen
        end
      else
        type.tok=acceptIt # natural,...
      end
      type
    end

    def parse_array_range_spec
      parse_expression
      if showNext.is_a? [:downto,:to]
        acceptIt
      end
      parse_expression
    end

    def parse_architecture
      archi=Architecture.new
      expect :architecture
      archi.name=expect(:ident)
      expect :of
      archi.entity_name=expect(:ident)
      expect :is
      parse_archi_decls
      parse_archi_body
      archi
    end

    def parse_archi_decls
      parse_decls
    end

    def parse_decls
      decls=[]
      while showNext.kind!=:begin and showNext.kind!=:end
        case showNext.kind
        when :constant
          decls << parse_constant
        when :type
          decls << parse_typedecl
        when :signal
          decls << parse_signal
        when :procedure
          decls << parse_procedure
        when :function
          decls << parse_function
        when :component
          decls << parse_component_decl
        when :attribute
          decls << parse_attribute
        when :variable
          decls << parse_variable
        else
          raise "ERROR : parse_decls #{pp showNext}"
        end
      end
      decls
    end

    def parse_constant
      expect :constant
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :colon
      parse_type
      initialized?
      expect :semicolon
    end

    def parse_typedecl
      expect :type
      expect :ident
      expect :is
      case showNext.kind
      when :lparen
        acceptIt
        expect :ident
        while showNext.is_a?(:comma)
          acceptIt
          expect :ident
        end
        expect :rparen
      when :record
        parse_record
      when :array
        parse_array
      else
        raise "parse_typedecl : #{pp showNext}"
      end
      expect :semicolon
    end

    def parse_record
      expect :record
      while showNext.not_a?(:end)
        parse_record_item
      end
      expect :end
      expect :record
    end

    def parse_record_item
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :colon
      parse_type
      expect :semicolon
    end

    def parse_array
      expect :array
      expect :lparen
      parse_array_ranges
      expect :rparen
      expect :of
      parse_type
    end

    def parse_array_ranges
      parse_array_range
      while showNext.is_a?(:comma) #multi dimensions
        acceptIt
        parse_array_range
      end
    end

    def parse_array_range
      case showNext.kind
      when :natural,:integer
        acceptIt
        expect :range
        expect :urange
      else
        niy
      end
    end

    def parse_signal
      expect :signal
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :colon
      parse_type
      initialized?
      expect :semicolon
    end

    def parse_procedure
      expect :procedure
      expect :ident
      if showNext.is_a?(:lparen)
        acceptIt
        parse_formal_parameters
        expect :rparen
      end
      if showNext.is_a?(:is)
        acceptIt
        parse_decls
        expect :begin
        parse_body
        expect :end
        maybe :procedure
        maybe :ident
      end
      expect :semicolon
    end

    def parse_formal_parameters
      ret=[]
      parse_formal_parameter
      while showNext.is_a?(:semicolon)
        acceptIt
        ret << parse_formal_parameter
      end
      ret.flatten!
      ret
    end

    def parse_formal_parameter
      maybe :signal
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :colon
      if showNext.is_a? [:in,:out,:inout]
        acceptIt
      end
      parse_type
    end

    def parse_function
      expect :function
      expect :ident
      if showNext.is_a?(:lparen)
        acceptIt
        parse_formal_parameters
        expect :rparen
      end

      expect :return
      parse_type

      unless showNext.is_a?(:semicolon)
        expect :is
        parse_decls
        expect :begin
        parse_body
        expect :end
        maybe :function
        maybe :ident
      end
      expect :semicolon
    end

    def parse_component_decl
      expect :component
      expect :ident
      maybe :is
      parse_generics?
      parse_ports
      expect :end
      expect :component
      expect :semicolon
    end

    def parse_attribute
      expect :attribute
      expect :ident
      case showNext.kind
      when :colon #declaration
        acceptIt
        parse_type
      when :of # specification
        acceptIt
        expect :ident
        expect :colon
        consume_to :semicolon
      else
        raise "ERROR : parse_attribute #{showNext}"
      end
      expect :semicolon
    end

    def parse_variable
      expect :variable
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :colon
      parse_type
      initialized?
      expect :semicolon
    end
    #======================================
    def parse_archi_body
      expect :begin
      while !showNext.is_a?(:end)
        parse_concurrent_stmt
      end
      expect :end
      expect :ident
      expect :semicolon
    end

    def parse_concurrent_stmt
      parse_label?
      case showNext.kind
      when :process
        parse_process
      when :entity
        parse_entity_instanciation
      when :ident # assign or component instanciation
        if lookahead(2).is_a?(:port)
          parse_component_instanciation
        else
          parse_assign
        end
      when :component
        parse_component_instanciation
      when :with
        parse_select
      else
        raise "parse_concurrent_stmt : #{pp showNext}"
      end
    end

    def parse_label?
      if lookahead(2).is_a?(:colon)
        expect(:ident)
        expect(:colon)
      end
    end

    def parse_process
      expect :process
      if showNext.is_a?(:lparen)
        parse_sensitivity_list
      end
      parse_decls
      expect :begin
      parse_body
      expect :end
      expect :process
      maybe :ident
      expect :semicolon
    end

    def parse_sensitivity_list
      expect :lparen
      expect :ident
      while showNext.is_a?(:comma)
        acceptIt
        expect :ident
      end
      expect :rparen
    end

    def parse_component_instanciation
      maybe :component
      expect :ident
      parse_generic_map?
      parse_port_map
      expect :semicolon
    end

    def parse_generic_map?
      if showNext.is_a? :generic
        acceptIt
        expect :map
        expect :lparen
        while !showNext.is_a?(:rparen)
          parse_assoc
          if showNext.is_a?(:comma)
            acceptIt
          end
        end
        expect :rparen
      end
    end

    def parse_entity_instanciation
      expect :entity
      expect :selected_name
      if showNext.is_a?(:lparen)
        acceptIt
        expect :ident
        expect :rparen
      end
      parse_generic_map?
      parse_port_map
      expect :semicolon
    end

    def parse_port_map
      expect :port
      expect :map
      expect :lparen
      while !showNext.is_a?(:rparen)
        parse_assoc
        if showNext.is_a?(:comma)
          acceptIt
        end
      end
      expect :rparen
    end

    def parse_assoc
      expect :ident
      if showNext.is_a?(:imply)
        acceptIt
        if showNext.is_a?(:open)
          acceptIt
        else
          parse_expression
        end
      end
    end

    def parse_select
      expect :with
      parse_expression
      expect :select
      parse_term
      expect :leq
      parse_selected_when
      while showNext.is_a?(:comma)
        acceptIt
        parse_selected_when
      end
      expect :semicolon
    end

    def parse_selected_when
      parse_expression
      expect :when
      parse_expression
    end
    #============== package

    def parse_package
      expect :package
      case showNext.kind
      when :ident
        parse_package_decl
      when :body
        parse_package_body
      else
        raise "ERROR : parse_package"
      end
    end

    def parse_package_decl
      expect :ident
      expect :is
      while !showNext.is_a?(:end)
        parse_decls
      end
      expect :end
      maybe :package
      maybe :ident
      expect :semicolon
    end

    def parse_package_body
      expect :body
      expect :ident
      expect :is
      while !showNext.is_a?(:end)
        parse_decls
      end
      expect :end
      maybe :package
      maybe :body
      maybe :ident
      expect :semicolon
    end

    # ============= configuration
    def parse_configuration
      expect :configuration
      expect :ident
      expect :of
      expect :ident
      expect :is
      parse_configuration_body
      expect :end
      expect :ident
      expect :semicolon
    end

    def parse_configuration_body
      case showNext.kind
      when :for
        parse_configuration_for
      else
        raise "ERROR : configurations not fully supported. Sorry."
      end
    end

    def parse_configuration_for
      expect :for
      expect :ident
      expect :end
      expect :for
      expect :semicolon
    end
    # ============== body
    def parse_body
      while !showNext.is_a?(:end) and !showNext.is_a?(:elsif) and !showNext.is_a?(:else) and !showNext.is_a?(:when)
        parse_seq_stmt
      end
    end

    def parse_seq_stmt
      #puts "parse_seq_stmt line #{showNext.pos.first}"
      parse_label?
      case showNext.kind
      when :null
        parse_null_stmt
      when :if
        parse_if_stmt
      when :for
        parse_for
      when :while
        parse_while
      when :case
        parse_case
      when :wait
        parse_wait
      when :report
        parse_report
      when :return
        parse_return
      when :assert
        parse_assert
      when :loop
        parse_loop
      when :exit
        parse_exit
      when :ident,:selected_name
        parse_assign
      else
        raise "ERROR : parse_seq_stmt : #{pp showNext}"
      end
    end

    def parse_null_stmt
      expect :null
      expect :semicolon
    end

    def parse_assign
      parse_term
      if showNext.is_a? [:vassign,:leq]
        acceptIt
      end

      parse_expression

      while showNext.is_a?(:comma)
        acceptIt
        parse_expression
      end

      while showNext.is_a?(:when) #cond assign
        got_when=true
        acceptIt
        parse_expression
        expect :else
        parse_expression
      end

      expect :semicolon
    end

    def parse_if_stmt
      expect :if
      parse_expression
      expect :then
      parse_body
      while showNext.is_a?(:elsif)
        parse_elsif
      end
      if showNext.is_a?(:else)
        acceptIt
        parse_body
      end
      expect :end
      expect :if
      expect :semicolon
    end

    def parse_elsif
      expect :elsif
      parse_expression
      expect :then
      parse_body
    end

    def parse_for
      expect :for
      expect :ident
      expect :in
      parse_expression
      if showNext.is_a? :to
        expect :to
        parse_expression
      end
      parse_loop

    end

    def parse_while
      expect :while
      parse_expression
      parse_loop
    end

    def parse_case
      expect :case
      parse_expression
      expect :is
      while showNext.is_a? :when
        parse_when_case
      end
      expect :end
      expect :case
      expect :semicolon
    end

    def parse_when_case
      expect :when
      parse_expression
      expect :imply
      parse_body
    end

    def parse_wait
      expect :wait
      case showNext.kind
      when :until
        acceptIt
        parse_expression
      when :for
        acceptIt
        parse_expression
      when :semicolon
      else
        raise "parse_wait : #{pp showNext}"
      end
      expect :semicolon
    end

    def parse_report
      if showNext.is_a?(:assert)
        parse_assert
      end
      expect :report
      parse_expression
      if showNext.is_a?(:severity)
        acceptIt
        if showNext.is_a? severity=[:warning,:note,:error]
          acceptIt
        else
          raise "ERROR : expecting one of #{severity.join(',')}. Got : #{showNext.val}"
        end
      end
      expect :semicolon
    end

    def parse_return
      expect :return
      parse_expression
      expect :semicolon
    end

    def parse_assert
      expect :assert
      parse_expression
    end

    def parse_loop #unusual loop...end loop
      expect :loop
      parse_body
      expect :end
      expect :loop
      maybe :ident
      expect :semicolon
    end

    #EXIT [ loop_label ] [ WHEN condition ] ;
    def parse_exit
      expect :exit
      if showNext.is_a?(:ident)
        acceptIt
      end
      if showNext.is_a?(:when)
        acceptIt
        parse_expression
      end
      expect :semicolon
    end

    # ============================= expression ===============================
    COMPARISON_OP=[:eq,:neq,:gt,:gte,:lt,:lte,:leq]
    def parse_expression
      t1=parse_additive
      while more? && showNext.is_a?(COMPARISON_OP)
        op=acceptIt
        t2=parse_additive
        t1=Binary.new(t1,op,t2)
      end
      return t1
    end

    ADDITIV_OP  =[:add,:sub, :or, :xor] #xor ?
    def parse_additive
      t1=parse_multiplicative
      while more? && showNext.is_a?(ADDITIV_OP)
        op=acceptIt #full token
        t2=parse_multiplicative
        t1=Binary.new(t1,op,t2)
      end
      return t1
    end

    MULTITIV_OP=[:mul,:div,:mod,:and,:shiftr,:shiftl]
    def parse_multiplicative
      t1=parse_term
      while more? && showNext.is_a?(MULTITIV_OP)
        op=acceptIt
        t2=parse_term
        t1=Binary.new(t1,op,t2)
      end
      return t1
    end

    def parse_term
      if showNext.is_a? [:ident,:selected_name,:decimal_literal,:char_literal,:string_literal,:bit_string_literal,:lparen,:others,:abs,:not,:sub]
        case showNext.kind
        when :ident
          ret=Identifier.new(acceptIt)
        when :lparen
          ret=parse_parenth
        when :not,:abs
          ret=parse_unary
        when :decimal_literal
          ret=IntLit.new(acceptIt)
        when :char_literal
          ret=acceptIt
        when :string_literal,:bit_string_literal
          ret=acceptIt
        when :selected_name
          ret=acceptIt
        when :others
          ret=acceptIt
        else
          puts "cannot parse term : #{showNext}"
        end
      end
      while showNext && showNext.is_a?([:lbrack,:attribute_literal,:lparen,:ns,:ps,:ms,:after,:ampersand])
        if par=parenthesized?
          #par.name=ret
          ret=par
        elsif attribute=attributed?
          #attribute.lhs=ret
          ret=attribute
        elsif timed=timed?
          timed.lhs=ret
          ret=timed
        elsif after=after?
          #after.lhs=ret
          ret=after
        elsif concat=concat?
          ret=concat
        end
      end
      ret
    end

    # parenthesized expressions (NOT indexed or funcall)
    def parse_parenth
      expect :lparen
      if showNext.is_a?(:others) # e.g : (others=>'0')
        acceptIt
        expect :imply
        parse_expression
      else
        parse_expression
      end

      while showNext.is_a?(:comma) # aggregate
        acceptIt
        parse_expression
      end
      expect :rparen
    end

    def parse_unary
      if showNext.is_a?([:not,:sub])
        acceptIt
        parse_expression
      end
    end

    def timed?
      if showNext.is_a? [:ps,:ns,:ms]
        tok=acceptIt
        ret=Timed.new(nil,tok)
      end
    end

    def parenthesized?
      if showNext.is_a? :lparen
        acceptIt
        ret=FuncCall.new
        args=[]
        while !showNext.is_a? :rparen
          args << parse_expression()
          while showNext.is_a? :comma
            acceptIt
            args << parse_expression()
          end
          if showNext.is_a? [:downto,:to] #slice !
            acceptIt
            parse_expression
          end
        end
        expect :rparen
        ret.actual_args = args
      else
        return false
      end
      return ret
    end

    def initialized?
      if showNext.is_a?(:vassign)
        acceptIt
        parse_expression
      end
    end

    def after?
      if showNext.is_a?(:after)
        acceptIt
        parse_expression
      end
    end

    def concat?
      if showNext.is_a?(:ampersand)
        acceptIt
        parse_expression
      end
    end

    def attributed?
      if showNext.is_a?(:attribute_literal)
        acceptIt
      end
    end
  end
end
