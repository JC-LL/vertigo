# coding: utf-8
require_relative 'generic_parser'
require_relative 'ast'
require_relative 'lexer'

module Vertigo

  class Parser < GenericParser
    attr_accessor :options
    attr_accessor :lexer,:tokens
    attr_accessor :basename,:filename

    def initialize options={}
      @options=options
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
        unless options[:mute]
          puts e.backtrace
          puts e
        end
        raise "an error occured during LEXICAL analysis. Sorry. Aborting."
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
        unless options[:mute]
          puts e.backtrace
          puts e
        end
      end
      root.flatten!
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
      ret=[]
      expect :library
      ret << lib=Library.new
      lib.name=Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << lib=Library.new
        lib.name=Ident.new(expect :ident)
      end
      expect :semicolon
      ret
    end

    def parse_use
      ret=Use.new
      expect :use
      selected_name=parse_term #ENSURE  selected_name
      unless selected_name.is_a?(SelectedName)
        raise "expecting selected name afer 'use'"
      end
      ret.library=selected_name.lhs.lhs
      ret.package=selected_name.lhs.rhs
      ret.element=selected_name.rhs
      expect :semicolon
      ret
    end

    def parse_entity
      entity=Entity.new
      expect :entity
      entity.name=Ident.new(expect :ident)
      expect :is
      entity.generics=parse_generics?
      if showNext.is_a? :port
        entity.ports=parse_ports
      end
      expect :end
      maybe :entity
      maybe :ident
      expect :semicolon
      return entity
    end

    def parse_generics?
      generics=[]
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
      end
      generics.flatten!
      return generics
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
      ids.map{|id|
        case dir
        when :in
          Input.new(id,type)
        when :out
          Output.new(id,type)
        when :inout
          InOut.new(id,type)
        end
      }
    end

    def parse_type
      case showNext.kind
      when :ident
        type=NamedType.new
        type.ident=Ident.new(acceptIt)
      else
        type=StdType.new
        type.ident=Ident.new(acceptIt) # natural,...
      end
      if showNext.is_a? :lparen
        type=ArrayType.new(type)
        acceptIt
        type.discrete_ranges << parse_discrete_range
        while showNext.is_a?(:comma) # multidim array types
          acceptIt
          type.discrete_ranges << parse_discrete_range
        end
        expect :rparen
      end
      type
    end

    def parse_discrete_range
      e1=parse_expression
      if showNext.is_a? [:downto,:to]
        dir=acceptIt
      end
      e2=parse_expression
      DiscreteRange.new(e1,dir,e2)
    end

    def parse_architecture
      archi=Architecture.new
      expect :architecture
      archi.name=expect(:ident)
      expect :of
      archi.entity_name=expect(:ident)
      expect :is
      archi.decls=parse_archi_decls
      archi.body=parse_archi_body
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
      decls.flatten!
      decls
    end

    def parse_constant
      ret=[]
      expect :constant
      ret << cst=Constant.new
      cst.name=Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << cst=Constant.new
        cst.name=Ident.new(expect :ident)
      end
      expect :colon
      type=parse_type
      ret.each{|cst| cst.type=type}
      expect :vassign
      ret.last.expr=parse_expression
      expect :semicolon
      ret
    end

    def parse_typedecl
      ret=TypeDecl.new
      expect :type
      ret.name=Ident.new(expect :ident)
      expect :is
      case showNext.kind
      when :lparen
        ret.spec=parse_enum
      when :record
        ret.spec=parse_record
      when :array
        ret.spec=parse_array
      else
        raise "parse_typedecl : #{pp showNext}"
      end
      expect :semicolon
      ret
    end

    def parse_enum
      ret=Enum.new
      expect :lparen
      ret << Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << Ident.new(expect :ident)
      end
      expect :rparen
      ret
    end

    def parse_record
      ret=Record.new
      expect :record
      while showNext.not_a?(:end)
        ret.elements << parse_record_items
      end
      ret.elements.flatten!
      expect :end
      expect :record
      ret
    end

    def parse_record_items
      ret=[]
      ret << ri=RecordItem.new
      ri.name=Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << ri=RecordItem.new
        ri.name=Ident.new(expect :ident)
      end
      expect :colon
      type=parse_type
      ret.each{|ri| ri.type=type}
      expect :semicolon
      ret
    end

    def parse_array
      ret=ArrayType.new
      expect :array
      expect :lparen
      ret.discrete_ranges=parse_array_ranges
      expect :rparen
      expect :of
      type=parse_type
      ret
    end

    def parse_array_ranges
      ret=[]
      ret << parse_array_range
      while showNext.is_a?(:comma) #multi dimensions
        acceptIt
        ret << parse_array_range
      end
      ret
    end

    def parse_array_range
      ret=DiscreteRange.new
      case showNext.kind
      when :natural,:integer
        acceptIt
        expect :range
        expect :urange
      else
        niy
      end
      ret
    end

    def parse_signal
      ret=[]
      expect :signal
      ret << sig=Signal.new
      sig.name=Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << sig=Signal.new
        sig.name=Ident.new(expect :ident)
      end
      expect :colon
      type=parse_type
      ret.map{|sig| sig.type=type}
      init=initialized?
      ret.last.init=init
      expect :semicolon
      ret
    end

    def parse_procedure
      ret=ProcedureDecl.new
      expect :procedure
      ret.name=Ident.new(expect :ident)
      if showNext.is_a?(:lparen)
        acceptIt
        ret.formal_args=parse_formal_args
        expect :rparen
      end
      if showNext.is_a?(:is)
        acceptIt
        ret.decls=parse_decls
        expect :begin
        ret.body=parse_body
        expect :end
        maybe :procedure
        maybe :ident
      end
      expect :semicolon
      ret
    end

    def parse_formal_args
      ret=[]
      ret << parse_formal_arg
      while showNext.is_a?(:semicolon)
        acceptIt
        ret << parse_formal_arg
      end
      ret.flatten!
      ret
    end

    def parse_formal_arg
      ret=[]
      is_signal=(maybe :signal)
      ret << fp=FormalArg.new
      fp.name=Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << fp=FormalArg.new
        fp.name=Ident.new(expect :ident)
      end
      expect :colon
      if showNext.is_a? [:in,:out,:inout]
        direction=acceptIt
      end
      type=parse_type
      ret.each{|fp|
        fp.direction=direction
        fp.type=type
      }
      ret
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
      ret=Body.new
      expect :begin
      while !showNext.is_a?(:end)
        ret << parse_concurrent_stmt
      end
      expect :end
      expect :ident
      expect :semicolon
      ret
    end

    def parse_concurrent_stmt
      label=parse_label?
      case showNext.kind
      when :process
        ret=parse_process
      when :entity
        ret=parse_entity_instanciation
      when :ident # assign or component instanciation
        if lookahead(2).is_a?(:port)
          ret=parse_component_instanciation
        else
          ret=parse_assign
        end
      when :component
        ret=parse_component_instanciation
      when :with
        ret=parse_select
      else
        raise "parse_concurrent_stmt : #{pp showNext}"
      end
      ret.label=label if label
      ret
    end

    def parse_label?
      if lookahead(2).is_a?(:colon)
        ret=Label.new
        ret.ident=Ident.new(expect(:ident))
        expect(:colon)
        return ret
      end
    end

    def parse_process
      ret=Vertigo::Process.new
      expect :process
      if showNext.is_a?(:lparen)
        ret.sensitivity=parse_sensitivity_list
      end
      ret.decls=parse_decls
      ret.decls.flatten!
      expect :begin
      ret.body=parse_body
      expect :end
      expect :process
      maybe :ident
      expect :semicolon
      ret
    end

    def parse_sensitivity_list
      ret=Sensitivity.new
      expect :lparen
      ret << Ident.new(expect :ident)
      while showNext.is_a?(:comma)
        acceptIt
        ret << Ident.new(expect :ident)
      end
      expect :rparen
      ret
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
      ret=EntityInstance.new
      expect :entity
      ret.full_name=parse_term # ENSURE :selected_name
      if showNext.is_a?(:lparen)
        acceptIt
        ret.arch_name=Ident.new(expect :ident)
        expect :rparen
      end
      ret.generic_map=parse_generic_map?
      ret.port_map=parse_port_map
      expect :semicolon
      ret
    end

    def parse_port_map
      ret=PortMap.new
      expect :port
      expect :map
      expect :lparen
      while !showNext.is_a?(:rparen)
        ret.elements << parse_map
        if showNext.is_a?(:comma)
          acceptIt
        end
      end
      expect :rparen
      ret
    end

    def parse_map
      ret=Map.new
      ret.lhs=parse_expression
      if showNext.is_a?(:imply)
        acceptIt
        if showNext.is_a?(:open)
          ret.rhs=acceptIt
        else
          ret.rhs=parse_expression
        end
      end
      ret
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
        ret=parse_package_decl
      when :body
        ret=parse_package_body
      else
        raise "ERROR : parse_package"
      end
    end

    def parse_package_decl
      ret=Package.new
      ret.name=Ident.new(expect :ident)
      expect :is
      while !showNext.is_a?(:end)
        ret.decls << parse_decls
      end
      ret.decls.flatten!
      expect :end
      maybe :package
      maybe :ident
      expect :semicolon
      ret
    end

    def parse_package_body
      ret=PackageBody.new
      expect :body
      ret.name=Ident.new(expect :ident)
      expect :is
      while !showNext.is_a?(:end)
        ret.decls << parse_decls
      end
      ret.decls.flatten!
      expect :end
      maybe :package
      maybe :body
      maybe :ident
      expect :semicolon
      ret
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
      ret=Body.new
      while !showNext.is_a?(:end) and !showNext.is_a?(:elsif) and !showNext.is_a?(:else) and !showNext.is_a?(:when)
        ret << parse_seq_stmt
      end
      ret
    end

    def parse_seq_stmt
      #puts "parse_seq_stmt line #{showNext.pos.first}"
      label=parse_label?
      case showNext.kind
      when :null
        ret=parse_null_stmt
      when :if
        ret=parse_if_stmt
      when :for
        ret=parse_for
      when :while
        ret=parse_while
      when :case
        ret=parse_case
      when :wait
        ret=parse_wait
      when :report
        ret=parse_report
      when :return
        ret=parse_return
      when :assert
        ret=parse_assert
      when :loop
        ret=parse_loop
      when :exit
        ret=parse_exit
      when :ident
        ret=parse_assign
      else
        raise "ERROR : parse_seq_stmt : #{pp showNext}"
      end
      ret
    end

    def parse_null_stmt
      ret=NullStmt.new
      expect :null
      expect :semicolon
      ret
    end

    def parse_assign
      lhs=parse_term
      if showNext.is_a? [:vassign,:leq]
        case showNext.kind
        when :vassign
          acceptIt
          ret=VarAssign.new(lhs)
        when :leq
          acceptIt
          ret=SigAssign.new(lhs)
        end
      end

      rhs=parse_expression

      case showNext.kind
      when :comma
        ret.rhs=wfm=Waveform.new
        wfm.elements << rhs
        while showNext.is_a?(:comma)
          acceptIt
          wfm.elements << parse_expression
        end
      when :when
        ret.rhs=cond=CondExpr.new
        while showNext.is_a?(:when) #cond assign
          cond.whens << when_=When.new
          got_when=true
          acceptIt
          when_.expr=rhs
          when_.cond=parse_expression
          expect :else
          rhs=parse_expression
        end
        cond.else_=rhs
      when :semicolon
        ret.rhs=rhs
      else
        raise "unexpected error in parse assign : #{showNext.val}"
      end
      expect :semicolon
      ret
    end

    def parse_if_stmt
      ret=If.new
      expect :if
      ret.cond=parse_expression
      expect :then
      ret.body=parse_body
      while showNext.is_a?(:elsif)
        ret.elsifs << parse_elsif
      end
      if showNext.is_a?(:else)
        ret.else_=parse_else
      end
      expect :end
      expect :if
      expect :semicolon
      ret
    end

    def parse_elsif
      ret=Elsif.new
      expect :elsif
      ret.cond=parse_expression
      expect :then
      ret.body=parse_body
      ret
    end

    def parse_else
      ret=Else.new
      expect :else
      ret.body=parse_body
      ret
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
      ret=Case.new
      expect :case
      ret.expr=parse_expression
      expect :is
      while showNext.is_a? :when
        ret << parse_when_case
      end
      expect :end
      expect :case
      expect :semicolon
      ret
    end

    def parse_when_case
      ret=CaseWhen.new
      expect :when
      ret.expr=parse_expression
      expect :imply
      ret.body=parse_body
      ret
    end

    def parse_wait
      ret=Wait.new
      expect :wait
      case showNext.kind
      when :until
        acceptIt
        ret.until_=parse_expression
      when :for
        acceptIt
        ret.for_=parse_expression
      when :semicolon
      else
        raise "parse_wait : #{pp showNext}"
      end
      expect :semicolon
      ret
    end

    def parse_report
      report=Report.new
      expect :report
      report.expr=parse_expression
      if showNext.is_a?(:severity)
        acceptIt
        if showNext.is_a? severity=[:warning,:note,:error]
          report.severity=acceptIt
        else
          raise "ERROR : expecting one of #{severity.join(',')}. Got : #{showNext.val}"
        end
      end
      expect :semicolon
      return report
    end

    def parse_return
      expect :return
      parse_expression
      expect :semicolon
    end

    def parse_assert
      ret=Assert.new
      expect :assert
      ret.cond=parse_expression
      if showNext.is_a?(:report)
        ret.report=parse_report
      end
      ret
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
      if showNext.is_a? [:ident,:dot,:decimal_literal,:char_literal,:string_literal,:bit_string_literal,:lparen,:others,:abs,:not,:sub]
        case showNext.kind
        when :ident
          ret=Ident.new(acceptIt)
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
        when :others
          ret=acceptIt
        else
          puts "cannot parse term : #{showNext}"
        end
      end

      while showNext && showNext.is_a?([:lbrack,:dot,:attribute_literal,:lparen,:ns,:ps,:ms,:after,:ampersand])
        if par=parenthesized?
          par.name=ret
          ret=par
        elsif selected_name=selected_name?
          selected_name.lhs=ret
          ret=selected_name
        elsif attribute=attributed?
          attribute.lhs=ret
          ret=attribute
        elsif timed=timed?
          timed.lhs=ret
          ret=timed
        elsif after=after?
          after.lhs=ret
          ret=after
        elsif concat=concat?
          concat.lhs=ret
          ret=concat
        end
      end
      ret
    end

    # parenthesized expressions (NOT indexed or funcall)
    def parse_parenth
      ret=Parenth.new
      expect :lparen

      ret.expr=expr=parse_expression
      if showNext.is_a?(:imply)
        ret=Assoc.new
        ret.lhs=expr
        acceptIt
        ret.rhs=parse_expression
      end

      if showNext.is_a?(:comma)
        ret=Aggregate.new
        ret << expr
        while showNext.is_a?(:comma) # aggregate
          acceptIt
          ret << parse_expression
        end
      end
      expect :rparen
      ret
    end

    def selected_name?
      while showNext.is_a? [:dot]
        ret=SelectedName.new
        acceptIt
        if showNext.is_a? [:ident,:all]
          case showNext.kind
          when :ident
            ret.rhs=Ident.new(acceptIt)
          when :all
            ret.rhs=acceptIt #all
          end
          return ret
        else
          raise "ERROR : expecting ident or 'all' at #{showNext.pos}"
        end
      end
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
        return parse_expression
      end
    end

    def after?
      if showNext.is_a?(:after)
        ret=After.new
        acceptIt
        ret.rhs=parse_expression
        return ret
      end
    end

    def concat?
      if showNext.is_a?(:ampersand)
        ret=Concat.new
        acceptIt
        ret.rhs=parse_expression
        return ret
      end
    end

    def attributed?
      if showNext.is_a?(:attribute_literal)
        ret=Attributed.new
        ret.rhs=acceptIt
        return ret
      end
    end
  end
end
