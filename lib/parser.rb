require 'pp'
require 'colorize'

require_relative 'generic_parser'
require_relative 'lexer'
require_relative 'indent'

require_relative 'ast'

module Vertigo

  class Parser < GenericParser

    include Indent

    attr_accessor :lexer,:tokens,:idents
    attr_accessor :basename
    attr_accessor :verbose

    def initialize options={}
      @options=options
      @verbose=@options[:verbose]
      @lexer=Lexer.new
      @stack=[]
      @stack_meth=[]
    end

    def parse filename
      root=Root.new
      begin
        lex filename
        while @tokens.any?
          root << design_unit()
          #puts "success for design unit".green
        end
      rescue Exception => e
        puts e.backtrace
        raise "parsing error"
      end
      return root
    end

    def lex filename
      @basename=File.basename(filename)
      str=IO.read(filename)
      str.downcase!
      @tokens=lexer.tokenize(str)
      @tokens=@tokens.select{|t| t.class==Token} # filters [nil,nil,nil]
      @tokens=@tokens.select{|tok| !tok.is_a? [:comment,:newline,:comments]}
      pp @tokens if @options[:show_tokens]
    end
    # ================ core methods =====================
    def several &block
      test=true
      while test
        begin
          ctxSave
          parse = yield
          ctxDel if parse
        rescue Exception => e
          ctxRestore
          test=false
        end
      end
    end

    def maybe kind
      if showNext.is_a? kind
        return acceptIt
      end
    end

    def maybe_one rule,&block
      say "maybe one ? #{rule}"
      begin
        ctxSave
        parse = self.send(rule)
        ctxDel if parse
      rescue  Exception => e
        ctxRestore
      end
    end

    def one_of rules
      i = 0
      begin
        ctxSave()
        spaces=" "*@stack.size
        say "\n#{spaces}#{path()}->(one of) #{rules[i]}"
        parse = self.send(rules[i])
        say "#{spaces}#{path()}->(one of) SUCCESS for #{rules[i]}"
        ctxDel()
        return parse #<=== this one should be the RIGHT one
        #return rules[i]
      rescue  Exception => e
        say "#{spaces}#{path()}->(one of) FAILURE for #{rules[i]}"
        methout()
        i+=1
        if i<rules.length
          ctxRestore()
          retry
        else
          message="#{spaces}#{path()} -> ERROR : expecting one of : #{rules.join(",")}"
          raise_it message
        end
      end
      return parse
    end

    def ctxSave
      @stack.push @tokens.clone
    end

    def ctxRestore
      @tokens=@stack.pop
    end

    def ctxDel
      @stack.pop
    end

    def ctxClean
      @stack.pop
      @stack.push @tokens
    end

    def raise_it str
      puts " "*(@stack_meth.size||1)+(@stack_meth.last||"?")+" FAILED" if @verbose
      @stack_meth.pop
      raise str
    end

    def path(last=8)
      tab= @stack_meth.last(last) || "/"
      tab.join(".")
      @stack_meth.last
    end

    def methin meth
      @stack_meth.push meth
      puts "-"*@stack_meth.size+"> #{meth}" if @verbose
      #puts " "*@stack.size*2+path() if @verbose
    end

    def methout
      @stack_meth.pop
      true
    end

    #........................................
    def comment
      methin "comment"
      expect :comment
      methout()
    end

    def comments
      while showNext and showNext.is_a? :comment
        comment()
      end
    end

    def design_unit
      methin "design_unit"
      design_unit=DesignUnit.new
      design_unit.context_clause=context_clause()
      design_unit.library_unit=library_unit()
      methout()
      return design_unit
    end

    def context_clause
      methin "context_clause"
      ret=ContextClause.new
      several {
        ret << context_item()
      }
      methout()
      ret
    end

    def context_item
      methin "context_item"
      case showNext.kind
      when :library
        ret=library_clause()
      when :use
        ret=use_clause()
      else
        raise_it "not a context_item"
      end
      methout()
      ret
    end

    def library_clause
      methin "library_clause"
      ret=LibraryClause.new
      expect(:library)
      ret << logical_name_list()
      ret.name_list.flatten!
      expect(:semicolon)
      methout()
      ret
    end

    def logical_name_list
      methin "logical_name_list"
      list=[]
      list << logical_name()
      several {
        expect(:comma)
        list << logical_name()
      }
      methout()
      return list
    end

    def logical_name
      methin "logical_name"
      ret=Ident.new expect(:identifier)
      methout()
      ret
    end

    def use_clause
      methin "use_clause"
      ret=UseClause.new
      expect(:use)
      ret << selected_name()
      several {
        expect :comma
        ret << selected_name()
      }
      expect :semicolon
      methout()
      ret
    end

    def selected_name
      methin "selected_name"
      ret=Ident.new expect(:selected_name) #token
      methout()
      ret
    end

    def library_unit
      methin "library_unit"

      if @tokens.size!=0
        case showNext.kind
        when :entity,:configuration
          ret=primary_unit()
        when :architecture
          ret=architecture_body()
        when :package
          ret=one_of([:package_declaration,:package_body])
        when :comment,:comments
          ret=Comment.new(acceptIt)
        else
          raise_it "not a library_unit around #{@tokens[0..4].collect{|t| (t.value ? t.value : t.kind)}.join(' ')}"
        end
      end
      methout()
      ret
    end

    def primary_unit
      methin "primary_unit"
      case showNext.kind
      when :entity
        ret=entity_declaration()
      when :package
        ret=package_declaration()
      when :configuration
        ret=configuration_declaration()
      else
        raise_it "not a primary_unit"
      end
      methout()
      ret
    end

    def debug message=""
      puts message.to_s.center(40,'-')
    end

    def entity_declaration
      methin "entity_declaration"
      entity=Entity.new
      expect(:entity)
      entity.name=Ident.new(expect(:identifier))
      expect(:is)
      ret=entity_header()
      entity.generics << ret[:generics]
      entity.generics.flatten!
      entity.ports << ret[:ports]
      entity.ports.flatten!
      expect :end
      maybe :entity
      maybe :identifier
      expect :semicolon
      methout()
      return entity
    end

    def entity_header
      methin "entity_header"
      ret={}
      if showNext.is_a? :generic
        ret[:generics]=formal_generic_clause()
      end
      if showNext.is_a? :port
        ret[:ports]=formal_port_clause()
      end
      methout()
      ret
    end

    def formal_generic_clause
      methin "formal_generic_clause"
      expect :generic
      expect :lparen
      ret=interface_list()
      expect :rparen
      expect :semicolon
      methout()
      ret
    end

    def formal_port_clause
      methin "formal_port_clause"
      expect(:port)
      expect :lparen
      list=port_list()
      expect :rparen
      expect :semicolon
      methout()
      return list
    end

    def port_list
      methin "port_list"
      list=interface_list()
      methout()
      return list
    end

    def interface_list
      methin "interface_list"
      list=[]
      list << interface_element()
      while showNext.is_a? :semicolon
        expect :semicolon
        list << interface_element()
      end
      methout()
      return list
    end

    def interface_element
      methin "interface_element"
      id=interface_declaration()
      methout()
      return id
    end

    def interface_declaration
      methin "interface_declaration"
      decl=one_of([ :interface_signal_declaration,
                    :interface_constant_declaration,
                    :interface_variable_declaration,
                    :interface_file_declaration])
      methout()
      return decl
    end

    def interface_file_declaration
      methin "interface_file_declaration"
      expect :file
      identifier_list()
      expect :colon
      subtype_indication()
      methout()
    end

    # def interface_signal_declaration
    #   methin "interface_signal_declaration"
    #   maybe :signal
    #   identifier_list()
    #   expect :colon
    #   mode()
    #   subtype_indication()
    #   maybe :bus
    #   if showNext.is_a? :vassign # optional [:= static_expression ]
    #     acceptIt
    #     expression()
    #   end
    #   methout()
    # end
    def interface_signal_declaration
      methin "interface_signal_declaration"
      decl=Declaration.new
      maybe :signal
      list=identifier_list()
      expect :colon
      decl.mode=mode()
      decl.type=subtype_indication()
      maybe :bus
      if showNext.is_a? :vassign # optional [:= static_expression ]
        acceptIt
        decl.init=expression()
      end
      methout()
      sigs=list.map do |e|
        sig=Declaration.new
        sig.ident=e
        sig.mode=decl.mode
        sig.type=decl.type
        sig.init=decl.init
        sig
      end
      return sigs
    end

    def interface_constant_declaration
      methin "interface_constant_declaration"
      maybe :constant
      identifier_list()
      expect :colon
      maybe_one :mode
      subtype_indication()
      maybe :bus
      if showNext.is_a? :vassign # optional [:= static_expression ]
        acceptIt
        expression()
      end
      methout()
    end

    def mode
      methin "mode"
      if showNext.is_a? [:in,:out,:inout,:buffer,:linkage]
        tok=acceptIt
        methout()
        return tok
      end
      methout()
    end

    def interface_variable_declaration
      methin "interface_variable_declaration"
      maybe :variable
      identifier_list()
      expect :colon
      maybe_one :mode
      subtype_indication()
      if showNext.is_a? :assign # optional [:= static_expression ]
        expression()
      end
      methout()
    end

    def variable_declaration
      say "variable_declaration"
      maybe :shared
      expect :variable
      identifier_list()
      expect :colon
      #maybe_one :mode
      subtype_indication()
      if showNext.is_a? :vassign # optional [:= static_expression ]
        acceptIt
        expression()
      end
      expect(:semicolon)
      methout()
    end

    def identifier_list
      methin "identifier_list"
      list=[]
      list << Ident.new(expect :identifier)
      several do
        expect(:comma)
        comments()
        list << Ident.new(expect :identifier)
      end
      methout()
      list
    end

    #------
    def entity_declarative_part
      methin "entity_declarative_part"
      raise_it "entity_declarative_part not supported"
    end


    # configuration_declaration ::=
    #       CONFIGURATION identifier OF entity_name IS
    #       	configuration_declarative_part
    #       	block_configuration
    #       END [ CONFIGURATION ] [ configuration_simple_name ] ;
    def configuration_declaration
      methin "configuration_declaration"
      expect :configuration
      expect :identifier
      expect :of
      expect :identifier
      expect :is
      configuration_declarative_part()
      several{ block_configuration() }
      expect :end
      maybe :configuration
      maybe :identifier
      expect :semicolon
      methout()
    end

    def configuration_declarative_part
      methin "configuration_declarative_part"
      comments()
      #several { :configuration_declarative_item }
      methout()
    end

    # configuration_declarative_item ::=
    #       use_clause
    #       | attribute_specification
    #       | group_declaration
    def configuration_declarative_item
      methin "configuration_declarative_item"
      one_of [:use_clause,:attribute_specification] #,:group_declaration]
      methout()
    end

    # attribute_specification ::=
    #       ATTRIBUTE attribute_designator OF entity_specification IS expression ;

    def attribute_specification
      methin "attribute_specification"
      expect :attribute
      attribute_designator
      expect :of
      entity_specification
      expect :is
      expression
      expect :semicolon
      methout()
    end

    def configuration_item
      one_of [:block_configuration,:component_configuration]
    end

    # block_configuration ::=
    #       FOR block_specification
    #       	{ use_clause }
    #       	{ configuration_item }
    #       END FOR ;
    def block_configuration
      methin "block_configuration"
      expect :for
      block_specification()
      #several { :use_clause }
      #several { :configuration_item }
      expect :end
      expect :for
      expect :semicolon
      methout()
    end

    # component_configuration ::=
    #       FOR component_specification
    #       	[ binding_indication ; ]
    #       	[ block_configuration ]
    #       END FOR ;
    def component_configuration
      methin "component_configuration"
      expect :for
      #component_specification()
      	#	[ binding_indication ; ]
  	#	[ block_configuration ]
  	#END FOR ;
      methout()
    end

    def component_specification
      methin "component_specification"
      methout()
    end

    # block_specification ::=
    # 	architecture_name
    # 	| block_statement_label
    # 	| generate_statement_label [ ( index_specification ) ]
    def block_specification
      methin "block_specification"
      if showNext.is_a? :identifier
        label=acceptIt
        if showNext.is_a? :lparen
          acceptIt
          index_specification()
          expect :rparen
        end
      else
      end
      methout()
    end

    # index_specification ::=
    #       discrete_range
    #       | static_expression
    def index_specification
      methin "index_specification"
      one_of [:discrete_range,:expression]
      methout()
    end

    #======= package =============

    # package_declaration ::=
    #       PACKAGE identifier IS
    #       	package_declarative_part
    #       END [ PACKAGE ] [ package_simple_name ] ;
    def package_declaration
      methin "package_declaration"
      expect :package
      expect :identifier
      expect :is
      comments()

      package_declarative_part()
      expect :end
      maybe :package
      maybe :identifier
      expect :semicolon
      methout()
    end

    def package_declarative_part
      methin "package_declarative_part"
      several { package_declarative_item() }
      methout()
    end

    def package_declarative_item
      methin "package_declarative_item"
      if showNext.is_a? :end #optimization
        raise_it "no package_declarative_item"
      else
        one_of [:subprogram_declaration,
                :type_declaration,
                :subtype_declaration,
                :constant_declaration,
                :signal_declaration,
                :variable_declaration,
                :file_declaration,
                :alias_declaration,
                :component_declaration,
                :attribute_specification,
                :use_clause] #:attribute_declaration,
        # :disconnection_specification
        # :group_template_declaration,
        # :group_declaration
        comments()
      end
        methout()
    end

    def constant_declaration
      methin "constant_declaration"
      expect :constant
      identifier_list()
      expect :colon
      subtype_indication()
      if showNext.is_a? :vassign
        acceptIt
        expression()
      end
      expect :semicolon
      comments()
      methout()
    end

    # architecture_body ::=
    #       ARCHITECTURE identifier OF entity_name IS
    #       	architecture_declarative_part
    #       BEGIN
    #       	architecture_statement_part
    #       END [ ARCHITECTURE ] [ architecture_simple_name ] ;
    def architecture_body
      methin "architecture_body"
      expect :architecture
      expect :identifier
      expect :of
      expect :identifier
      expect :is
      architecture_declarative_part()
      expect :begin
      comments()
      architecture_statement_part()
      comments()
      expect :end
      maybe :architecture
      maybe :identifier
      expect :semicolon

      comments()
      #puts10
      methout()
    end

    def architecture_declarative_part
      methin "architecture_declarative_part"
      several { block_declarative_item() }
      methout()
    end

    # block_declarative_item ::=
    #       subprogram_declaration
    #       | subprogram_body
    #       | type_declaration
    #       | subtype_declaration
    #       | constant_declaration
    #       | signal_declaration
    #       | shared_variable_declaration
    #       | file_declaration
    #       | alias_declaration
    #       | component_declaration
    #       | attribute_declaration
    #       | attribute_specification
    #       | configuration_specification
    #       | disconnection_specification
    #       | use_clause
    #       | group_template_declaration
    #       | group_declaration

    def block_declarative_item
      methin "block_declarative_item"
      comments()

      case showNext.kind
      when :signal
        signal_declaration()
      when :component
        component_declaration()
      when :constant
        constant_declaration()
      when :type
        type_declaration()
      when :subtype
        subtype_declaration()
      when :procedure,:pure,:impure,:function
        one_of [:subprogram_body,:subtype_declaration]
      when :attribute
        attribute()
      when :alias,:for,:disconnect,:use,:group
        puts "NIY- block_declarative_item"
        raise_it "ERROR"
      else
        raise_it "not a block_declarative_item"
      end
      methout()
    end

    # signal_declaration ::=
    #       signal identifier_list : subtype_indication [ signal_kind ] [ := expression ] ;
    def signal_declaration
      methin "signal_declaration"
      expect(:signal)
      identifier_list()
      expect(:colon)
      subtype_indication()
      if showNext.is_a? [:bus,:register]
        acceptIt
      end
      if showNext.is_a? [:vassign]
        acceptIt
        expression()
      end
      expect(:semicolon)
      methout()
    end

    # component_declaration ::=
    #       COMPONENT identifier [ IS ]
    #       	[ local_generic_clause ]
    #       	[ local_port_clause ]
    #       END COMPONENT [ component_simple_name ] ;
    def component_declaration
      methin "component_declaration"
      expect :component
      expect :identifier
      maybe :is
      if showNext.is_a? :generic
        formal_generic_clause() #?
      end
      if showNext.is_a? :port
        formal_port_clause()
      end
      expect :end
      expect :component
      maybe :identifier
      expect :semicolon
      methout()
    end

    # subprogram_declaration ::=
    #       subprogram_specification ;
    def subprogram_declaration
      methin "subprogram_declaration"
      subprogram_specification()
      expect :semicolon
      methout()
    end

    # subprogram_specification ::=
    #       PROCEDURE designator [ ( formal_parameter_list ) ]
    #       | [ PURE | IMPURE ]  FUNCTION designator [ ( formal_parameter_list ) ]
    #       	RETURN type_mark
    def subprogram_specification
      methin "subprogram_specification"
      if showNext.is_a? :procedure
        acceptIt
        designator()
        if showNext.is_a? :lparen
          acceptIt
          interface_list()
          expect :rparen
        end
      elsif showNext.is_a? [:pure,:impure,:function]
        if showNext.is_a? [:pure,:impure]
          acceptIt
        end
        expect :function
        designator()
        if showNext.is_a?  :lparen
          acceptIt
          interface_list()
          expect :rparen
        end
        expect :return
        type_mark()
      else
        raise_it "subprogram_specification error"
      end
      methout()
    end

    # subprogram_declarative_item ::=
    # 	subprogram_declaration
    # 	| subprogram_body
    # 	| type_declaration
    # 	| subtype_declaration
    # 	| constant_declaration
    # 	| variable_declaration
    # 	| file_declaration
    # 	| alias_declaration
    # 	| attribute_declaration
    # 	| attribute_specification
    # 	| use_clause
    # 	| group_template_declaration
    # 	| group_declaration

    def subprogram_declarative_item
      methin "subprogram_declarative_item"
      one_of [
              :subprogram_body,
              :subprogram_declaration,
              :type_declaration,
              :subtype_declaration,
              :constant_declaration,
              :variable_declaration,
              :file_declaration,
              :attribute_specification,
              :use_clause]
      # attribute_declaration
      #group_template_declaration,
      #group_declaration,
      methout()
    end

    def alias_declaration
      methin "alias_declaration"
      expect :alias
      designator
      if showNext.is_a? :colon
        subtype_indication()
      end
      expect :is
      name()
      maybe_one :signature
      expect :semicolon
      methout()
    end
    # subprogram_body ::
    # subprogram_specification IS
    #       	subprogram_declarative_part
    #       BEGIN
    #       	subprogram_statement_part
    #       END [ subprogram_kind ] [ designator ] ;
    def subprogram_body
      methin "subprogram_body"
      subprogram_specification()
      expect :is
      comments()
      subprogram_declarative_part()
      expect :begin
      comments()
      subprogram_statement_part()
      expect :end
      if showNext.is_a? [:procedure,:function]
        acceptIt
      end
      #maybe_one :identifier : does not seem to work ?????
      if showNext.is_a? :identifier
        acceptIt
      end
      expect :semicolon
      methout()
    end

    def subprogram_declarative_part
      methin "subprogram_declarative_part"
      several { subprogram_declarative_item() }
      methout()
    end

    def designator
      methin "designator"
      if showNext.is_a? :identifier
        acceptIt
      else
        operator_symbol()
      end
      methout()
    end

    def subprogram_statement_part
      methin "subprogram_statement_part"

      several { sequential_statement() }
      methout()
    end

    def architecture_statement_part
      methin "architecture_statement_part"
      comments()
      if showNext.kind !=:end
       several{concurrent_statement()}
      end
      methout()
    end

    # concurrent_statement ::=
    #   block_statement
    # | process_statement
    # | concurrent_procedure_call_statement
    # | concurrent_assertion_statement
    # | concurrent_signal_assignment_statement
    # | component_instantiation_statement
    # | generate_statement

    def concurrent_statement
      methin "concurrent_statement"
      comments()
      maybe_one :label
      one_of [:concurrent_signal_assignment_statement,
              :process_statement,
              :component_instantiation_statement,
              :generate_statement
             ]
      methout()
    end

    def label
      methin "label"
      expect(:identifier)
      expect(:colon)
      methout()
    end

    # concurrent_signal_assignment_statement ::=
    #         [ label : ] [ POSTPONED ] conditional_signal_assignment
    #       | [ label : ] [ POSTPONED ] selected_signal_assignment
    def concurrent_signal_assignment_statement
      methin "concurrent_signal_assignment_statement"
      one_of [:conditional_signal_assignment,
              :selected_signal_assignment]
      methout()
    end

    # conditional_signal_assignment ::=
    #       target	<= options conditional_waveforms ;
    def conditional_signal_assignment
      methin "conditional_signal_assignement"
      #show_following_tokens
      target()
      expect :sassign
      maybe_one :options
      conditional_waveforms()
      expect :semicolon
      methout()
    end

    # conditional_waveforms ::=
    #       { waveform WHEN condition ELSE }
    #       waveform [ WHEN condition ]
    def conditional_waveforms
      methin "conditional_waveforms"
      waveform()
      while showNext.is_a? :when
        acceptIt
        expression()
        if showNext.is_a? :else
          acceptIt
          waveform()
        end
      end
      methout()
    end


    # selected_signal_assignment ::=
    # 	WITH expression SELECT
    # 		target	<= options selected_waveforms ;
    def selected_signal_assignment
      methin "selected_signal_assignment"
      expect :with
      expression()
      expect :select
      target()
      expect :sassign
      maybe_one :options
      selected_waveforms()
      expect :semicolon
      methout()
    end

    #options ::= [ GUARDED ] [ delay_mechanism ]
    def options
      methin "options"
      maybe :guarded
      delay_mechanism()
      methout()
    end

    # selected_waveforms ::=
    # 	{ waveform WHEN choices , }
    # 	waveform WHEN choices
     def selected_waveforms
       methin "selected_waveforms"
       waveform()
       expect :when
       choices()
       while showNext.is_a? :comma
         acceptIt
         waveform()
       expect :when
       choices()
       end
       methout()
     end
    #  generate_statement ::=
    #  	generate_label :
    #  		generation_scheme GENERATE
    #  			[ { block_declarative_item }
    #  		BEGIN ]
    #  			{ concurrent_statement }
    #  		END GENERATE [ generate_label ] ;
    def generate_statement
      methin "generate_statement"
      if showNext.is_a? [:for,:if]
        generation_scheme()
        expect :generate
        #several { block_declarative_item() }
        if showNext.is_a? :begin
          acceptIt
        end
        if showNext.kind !=:end
         several{concurrent_statement()}
        end
        expect :end
        expect :generate
        if showNext.is_a? :identifier
          label()
        end
        expect :semicolon
      else
        raise "no generate statement"
      end
      methout
    end

    # generation_scheme ::=
    # 	FOR generate_parameter_specification
    # 	| IF condition
    def generation_scheme
      methin "generation_scheme"
      if showNext.is_a? :for
        expect :for
        parameter_specification()
      elsif showNext.is_a? :if
        expect :if
        expression()
      else
        raise "no generation scheme"
      end
      methout
    end

    # process_statement ::=
    #       	[ POSTPONED ] PROCESS [ ( sensitivity_list ) ] [ IS ]
    #       		process_declarative_part
    #       	BEGIN
    #       		process_statement_part
    #       	END [ POSTPONED ] PROCESS [ process_label ] ;
    def process_statement
      methin "process_statement"
      expect :process
      maybe_one :sensitivity_list
      maybe :is
      comments()
      process_declarative_part()
      expect :begin
      process_statement_part()
      comments()
      expect :end
      expect :process
      maybe :identifier
      expect :semicolon
      methout()
    end

    def sensitivity_list
      methin "sensitivity_list"
      rparen_req=false
      if showNext.is_a? :lparen
        acceptIt
        rparen_req=true
      end
      name()
      while showNext.is_a? :comma
        acceptIt
        name()
      end
      if rparen_req
        expect :rparen
      end
      methout()
    end

    def process_declarative_part
      methin "process_declarative_part"
      several{process_declarative_item()}
      methout()
    end

    # process_declarative_item ::=
    #       subprogram_declaration
    #       | subprogram_body
    #       | type_declaration
    #       | subtype_declaration
    #       | constant_declaration
    #       | variable_declaration
    #       | file_declaration
    #       | alias_declaration
    #       | attribute_declaration
    #       | attribute_specification
    #       | use_clause
    #       | group_template_declaration
    #       | group_declaration
    def process_declarative_item
      methin "process_declarative_item"
      comments()
      case showNext.kind
      when :variable
        variable_declaration()
      when :constant
        constant_declaration()
      when :type
        type_declaration()
      when :subtype
        subtype_declaration()
      when :procedure,:pure,:impure,:function
        subprogram_declaration()
      when :alias,:attribute,:use,:group
        raise_it "NIY!"
      else
        raise_it "not a block_declarative_item"
      end
      methout()
    end

    def process_statement_part
      methin "process_statement_part"
      while showNext.kind!=:end
        comments()
        if showNext.kind!=:end
          sequential_statement()
        end
      end
      methout()
    end

    # ----------------------------- sequential statements -----------------------------
    # sequential_statement ::=
    #        wait_statement
    #        | assertion_statement
    #        | report_statement
    #        | signal_assignment_statement
    #        | variable_assignment_statement
    #        | procedure_call_statement
    #        | if_statement
    #        | case_statement
    #        | loop_statement
    #        | next_statement
    #        | exit_statement
    #        | return_statement
    #        | null_statement
    def sequential_statement
      methin "sequential_statement"
      comments()
        maybe_one :label
        case showNext.kind
        when :if
            if_statement()
        when :case
          case_statement()
        when :wait
          wait_statement()
          #abort
        when :report
          report_statement()
        when :assert
          assertion_statement()
        when :for,:while,:loop
          loop_statement()
        when :return
          return_statement()
        when :null
          null_statement()
        when :exit
          exit_statement()
        else
          #show_following_tokens
          one_of [
            :variable_assignment_statement,
            :procedure_call_statement,
            :signal_assignment_statement,
          ]
      end
      methout()
    end

    # can be empty !!!
    def sequence_of_statements
      methin("sequence_of_statements")
      while ! showNext.is_a? [:else,:elsif,:end,:when]
        sequential_statement()
        #puts "sos 1".center(40,'=')
        comments()
      end
      methout()
    end

    # wait_statement ::=
    #  [ label : ] WAIT [ sensitivity_clause ] [ condition_clause ] [ timeout_clause ] ;
    def wait_statement
      methin "wait_statement"
      expect :wait
      if showNext.is_a? :on
        acceptIt
        if showNext.is_a? :lparen
          sensitivity_list()
          expect :rparen
        else
          sensitivity_list()
        end
      end
      if showNext.is_a? :until
          acceptIt
        expression()
      end
      if showNext.is_a? :for
        acceptIt
        expression()
      end
      expect :semicolon
      methout()
    end

    # assertion ::=
    # ASSERT condition
    # 	[ REPORT expression ]
    # 	[ SEVERITY expression ]
    def assertion_statement
      methin "assertion_statement"
      expect :assert
      expression()
      if showNext.is_a? :report
        acceptIt
        expression()
      end
      if showNext.is_a? :severity
        acceptIt
        expect :identifier
      end
      expect :semicolon
      methout()
    end

    #report_statement ::=[ label : ] REPORT expression [ SEVERITY expression ] ;
    def report_statement
      methin "report_statement"
      expect :report
      expression()
      if showNext.is_a? :severity
        acceptIt
        expression()
      end
      expect :semicolon
      methout()
    end

    #signal_assignment_statement ::=[ label : ] target <= [ delay_mechanism ] waveform ;
    def signal_assignment_statement
      methin "signal_assignment_statement"
      #show_following_tokens(true)
      target()
      expect :sassign
      if showNext.is_a? [:transport,:reject,:inertial]
        delay_mechanism()
      end
      waveform()
      expect :semicolon
      maybe_one :comment
      methout()
    end

    def target
      methin "target"
      # if showNext.is_a? :lparen
      #   aggregate()
      # else
      #   name()
      # end
      term
      methout()
    end

    # aggregate ::=
    # 	( element_association { , element_association } )
    def aggregate
      methin "aggregate"
      expect :lparen
      element_association()
      while showNext.is_a? :comma
        acceptIt
        element_association()
      end
      expect :rparen
      methout()
    end

    # element_association ::=
    #       [ choices => ] expression
    def element_association
      methin "element_association"
      one_of [
        :choices_imply_expression,
        :expression
      ]
      methout
    end

    # choices => expression
    def choices_imply_expression
      choices
      expect :imply
      expression
    end

    #delay_mechanism ::= TRANSPORT | [ REJECT time_expression ] INERTIAL
    def delay_mechanism
      methin "delay_mechanism"
      if showNext.is_a? :transport
        acceptIt
      elsif showNext.is_a? [:reject,:inertial]
        if showNext.is_a? :reject
          acceptIt
          expression()
        end
        expect :inertial
      else
        raise_it "not a delay mecanism"
      end
      methout()
    end

    #waveform ::= waveform_element { , waveform_element } | UNAFFECTED
    def waveform
      methin "waveform"
      if showNext.is_a? :unaffected
        acceptIt
      else
        waveform_element()
        while showNext.is_a? :comma
          acceptIt
          waveform_element()
        end
      end
      methout()
    end

    #waveform_element ::= value_expression [ AFTER time_expression ] | NULL [ AFTER time_expression ]
    def waveform_element
      methin "waveform_element"
      show_following_tokens
      if showNext.is_a? :null
        acceptIt
        if showNext.is_a? :after
          acceptIt
          expression()
        end
      else

        expression()
        if showNext.is_a? :after
          acceptIt
          expression()
        end
      end
      methout()
    end

    #variable_assignment_statement ::=[ label : ] target  := expression ;
    def variable_assignment_statement
      methin "variable_assignment_statement"
      target()
      expect :vassign
      expression()
      expect :semicolon
      methout()
    end

    #procedure_call_statement ::=[ label : ] procedure_call ;
    def procedure_call_statement
      methin "procedure_call_statement"
      #puts "procedure_call_statement".cyan
      procedure_call()
      expect :semicolon
      methout()
    end

    #procedure_call ::= procedure_name [ ( actual_parameter_part ) ]
    def procedure_call
      methin "procedure_call"
      ##show_following_tokens
      expect :identifier
      if showNext.is_a? :lparen
        acceptIt
        association_list()
        expect :rparen
      end
      methout()
    end

    # if_statement ::=[ if_label : ]
    #       	IF condition THEN
    #       		sequence_of_statements
    #       	{ ELSIF condition THEN
    #       		sequence_of_statements }
    #       	[ ELSE
    #       		sequence_of_statements ]
    #       	END IF [ if_label ] ;
    def if_statement
      methin "if_statement"
      expect :if
      expression()
      expect :then
      comments()
      sequence_of_statements()
      while showNext.is_a? :elsif
        acceptIt
        expression()
        expect :then
        comments()
        sequence_of_statements()
      end
      if showNext.is_a? :else
        acceptIt
        comments()
        sequence_of_statements()
      end
      expect :end
      expect :if
      maybe :identifier
      expect :semicolon
      methout()
    end

    #case_statement ::=[ case_label : ]CASE expression IS case_statement_alternative { case_statement_alternative } END CASE [ case_label ] ;
    def case_statement
      methin "case_statement"
      expect :case
      expression
      expect :is
      case_statement_alternative()
      while showNext.kind!=:end
        case_statement_alternative()
      end
      expect :end
      expect :case
      maybe :identifier
      expect :semicolon
      methout()
    end

    #case_statement_alternative ::=	WHEN choices =>		sequence_of_statements
    def case_statement_alternative
      methin "case_statement_alternative"
      expect :when
      choices()
      #puts "csa 1".center(40,'=')
      expect :imply
      sequence_of_statements()
      #puts "csa 2".center(40,'=')

      methout()
    end

    #choices ::= choice { | choice }
    def choices
      methin "choices"
      choice()
      while showNext.is_a? :bar
        acceptIt
        choice()
      end
      methout()
    end

    # choice ::=
    #       simple_expression
    #       | discrete_range
    #       | element_simple_name
    #       | OTHERS

    def choice
      methin "choice"
      if showNext.is_a? :others
        acceptIt
      else
        one_of [:simple_expression,:discrete_range]
      end
      methout()
    end

    #loop_statement ::=[ loop_label : ][ iteration_scheme ] LOOP sequence_of_statements END LOOP [ loop_label ] ;
    def loop_statement
      methin "loop_statement"
      maybe_one :iteration_scheme
      expect :loop ; comments()
      sequence_of_statements
      expect :end
      expect :loop
      maybe :identifier
      expect :semicolon
      methout()
    end

     # WHILE condition
     #  | FOR loop_parameter_specification
    def iteration_scheme
      methin "iteration_scheme"
      if showNext.is_a? :while
          acceptIt
        expression()
      else
        expect :for
        parameter_specification()
      end
      methout()
    end

    # parameter_specification ::=
    #       identifier IN discrete_range
    def parameter_specification
      methin "parameter_specification"
      expect :identifier
      expect :in
      discrete_range()
      methout()
    end
  #next_statement ::=[ label : ] NEXT [ loop_label ] [ WHEN condition ] ;
    def next_statement
      methin "next_statement"
      expect :next
      maybe :identifier #[ loop_label ]
      if showNext.is_a? :when
        acceptIt
        expression()
      end
      expect :semicolon
      methout()
    end
    #exit_statement ::=[ label : ] EXIT [ loop_label ] [ WHEN condition ] ;
    def exit_statement
      methin "exit_statement"
      expect :exit
      maybe :identifier #[ loop_label ]
      if showNext.is_a? :when
        acceptIt
        expression()
      end
      expect :semicolon
      methout()
    end
    #return_statement ::=[ label : ] RETURN [ expression ] ;
    def return_statement
      methin "return_statement"
      expect :return
      if showNext.kind!=:semicolon
        expression()
      end
      expect :semicolon
      methout()
    end

    #null_statement ::= [ label : ] NULL ;
    def null_statement
      methin "null_statement"
      expect :null
      expect :semicolon
      methout()
    end

    # ------------------- instantiation stuff --------------------------
    def component_instantiation_statement
      methin "component_instantiation_statement"
      instantiated_unit()
      maybe_one :generic_map_aspect
      maybe_one :port_map_aspect
      expect :semicolon
      methout()
    end

    # instantiated_unit ::=
    # 	[ COMPONENT ] component_name
    # 	| ENTITY entity_name [ ( architecture_identifier ) ]
    # 	| CONFIGURATION configuration_name
    def instantiated_unit
      methin "instantiated_unit"
      case showNext.kind
      when :component
        acceptIt;
        name()
      when :identifier
        acceptIt
      when :entity
        acceptIt
        ##pp showNext
        expect :selected_name
        if showNext.is_a? :lparen
          acceptIt
          name()
          expect :rparen
        end
      when :configuration
        acceptIt
        name()
      else
        raise_it "tried an instantiated_unit unsuccessfully"
      end
      methout()
    end

    # generic_map_aspect ::=
    #       GENERIC MAP ( generic_association_list )
    def generic_map_aspect
      methin "generic_map_aspect"
      expect :generic
      expect :map
      expect :lparen
      association_list()
      expect :rparen
      expect :semicolon
      methout()
    end

    # port_map_aspect ::=
    #       PORT MAP ( port_association_list )
    def port_map_aspect
      methin "port_map_aspect"
      expect :port
      expect :map
      expect :lparen
      association_list()
      expect :rparen
      methout()
    end

    def association_list
      methin "association_list"
      association_element()
      while showNext.is_a? :comma
        acceptIt
        association_element()
      end
      methout()
    end

    # association_element ::=
    # 	[ formal_part => ] actual_part
    # this association_element is STRANGE...
    # here I simplified :
    # formal_part : identifier...
    # actual_part : name | literal, OPEN
    def association_element
      methin "association_element"
      #puts "ae 1".center(40,'=')
      name()
      if showNext.is_a? :imply
        acceptIt
        if showNext.is_a? :open
          acceptIt
        else
          expression
        end
      end
      methout()
    end

    # package_body ::=
    #       PACKAGE body package_simple_name IS
    #       	package_body_declarative_part
    #       END [ PACKAGE BODY ] [ package_simple_name ] ;
    def package_body
      methin "package_body"
      expect :package
      expect :body
      expect :identifier
      expect :is
      comments
      package_body_declarative_part()
      expect :end
      if showNext.is_a? :package
        acceptIt
        expect :body
      end
      maybe :identifier
      expect :semicolon
      methout()
    end

    def package_body_declarative_part
      methin "package_body_declarative_part"
      several { package_body_declarative_item() }
      methout()
    end

    def package_body_declarative_item
      methin "package_body_declarative_item"
      one_of [:subprogram_body, #:subprogram_declaration,
              :type_declaration,
              :subtype_declaration,
              :constant_declaration,
              :variable_declaration,
              :file_declaration,
              :alias_declaration,
              :use_clause]
      	#group_template_declaration
  	#group_declaration
      methout()
    end

    def file_declaration
      methin "file_declaration"
      expect :file
      identifier_list()
      expect :colon
      subtype_indication()
      [file_open_information ]
      expect :semicolon
      methout()
    end

    def file_open_information
      methin "file_open_information"
      if showNext.is_a? :open
        expression()
      end
      expect :is
      expression()
      methout()
    end

    def type_declaration
      methin "type_declaration"
      expect :type
      expect :identifier
      expect :is
      type_definition()
      expect :semicolon
      methout()
    end

    # type_definition ::=
    #       scalar_type_definition
    #       | composite_type_definition
    #       | access_type_definition
    #       | file_type_definition

    # WARNING : remember that if a method is not declared, the exception won't be seen easily
    def type_definition
      methin "type_definition"
      one_of [:scalar_type_definition,
              :composite_type_definition,
              :access_type_definition,
              :file_type_definition]
      methout()
    end

    # composite_type_definition ::=
    #       array_type_definition
    #       | record_type_definition
    def composite_type_definition
      methin "composite_type_definition"
      one_of [:array_type_definition,
              :record_type_definition]
      methout()
    end

    # scalar_type_definition ::=
    #       enumeration_type_definition   | integer_type_definition
    #       | floating_type_definition	  | physical_type_definition
    def scalar_type_definition
      methin "scalar_type_definition"
      one_of [:enumeration_type_definition,
              :integer_type_definition,
              :floating_type_definition,
              :physical_type_definition]
      methout
    end

    # enumeration_type_definition ::=
    #       ( enumeration_literal { , enumeration_literal } )
    def enumeration_type_definition
      methin "enumeration_type_definition"
      expect :lparen
      enumeration_literal()
      several do
        expect :comma
        enumeration_literal()
      end
      expect :rparen
      methout
    end

    def enumeration_literal
      methin "enumeration_literal"
      if showNext.is_a? :identifier
        acceptIt
      elsif showNext.is_a? :char_literal
        acceptIt
      else
        raise_it "error in enumeration_literal"
      end
      methout()
    end

    # array_type_definition ::=
    #       unconstrained_array_definition	|   constrained_array_definition
    def array_type_definition
      methin "array_type_definition"
      one_of [:unconstrained_array_definition , :constrained_array_definition]
      methout()
    end
    # unconstrained_array_definition ::=
    #       ARRAY ( index_subtype_definition { , index_subtype_definition } )
    #       	OF element_subtype_indication
    def unconstrained_array_definition
      methin "unconstrained_array_definition"
      expect :array
      expect :lparen
      index_subtype_definition()
      while showNext.is_a? :comma
        acceptIt
        index_subtype_definition()
      end
      expect :rparen
      expect :of
      subtype_indication()
      methout()
    end
    # constrained_array_definition ::=
    #       ARRAY index_constraint OF element_subtype_indication
    def constrained_array_definition
      methin "constrained_array_definition"
      expect :array
      index_constraint()
      expect :of
      subtype_indication()
      methout()
    end
    #index_subtype_definition ::= type_mark range <>
    def index_subtype_definition
      methin "index_subtype_definition"
      type_mark()
      expect :range
      expect :urange
      methout()
    end
    # record_type_definition ::=
    #       RECORD
    #       	element_declaration
    #       	{ element_declaration }
    #       END RECORD [ record_type_simple_name ]
    def record_type_definition
      methin "record_type_definition"
      expect :record
      several { element_declaration() }
      expect :end
      expect :record
      maybe :identifier
      methout()
    end

    # element_declaration ::=
    #       identifier_list : element_subtype_definition ;
    def element_declaration
      methin "element_declaration"
      identifier_list()
      expect :colon
      subtype_indication()
      expect :semicolon
      comments()
      methout()
    end

    def subtype_declaration
      methin "subtype_declaration"
      expect :subtype
      expect :identifier
      expect :is
      subtype_indication()
      expect :semicolon
      methout()
    end

    def prefix
      methin "prefix"
      maybe_one :name  #[:name,:function_call]
      methout()
    end

    def suffix
      methin "suffix"
      if showNext.is_a? :all
        acceptIt
      else
        one_of [:simple_name,:character_literal,:operator_symbol]
      end
      methout()
    end


    #--------------- name stuff ----------------
    def name
      methin "name"
      #show_following_tokens
      case showNext.kind
      when :selected_name
        acceptIt()
      when :identifier
        #show_following_tokens(true)
        one_of [:slice_name,:indexed_name,:simple_name]
      when :string_literal
        operator_symbol()
      else
        raise_it "not a name : #{showNext.value} "
      end
      #.......attribute_name are processed here!!!......
      unless showNext.nil?
        if showNext.is_a?(:attribute_designator)
          acceptIt
        end
      end
      #.................................................
      methout()
    end

    def simple_name
      methin "simple_name"
      ##show_following_tokens
      expect(:identifier)
      methout()
    end

    def operator_symbol
      methin "operator_symbol"
      expect(:string_literal)
      methout()
    end

    #indexed_name ::= prefix ( expression { , expression } )
    def indexed_name
      methin "indexed_name"
      #show_following_tokens(true)
      if showNext.is_a? :selected_name
        acceptIt
      else
        expect(:identifier)
      end

      expect :lparen
      expression()
      while showNext.is_a? :comma
        acceptIt
        expression()
      end
      expect :rparen

      methout()
    end

    #slice_name ::=	prefix ( discrete_range )
    def  slice_name
      methin "slice_name"
      if showNext.is_a? :selected_name
        acceptIt
      else
        expect(:identifier)
      end
      expect :lparen
      discrete_range()
      expect :rparen
    end

    #discrete_range ::= discrete_subtype_indication | range
    def discrete_range
      methin "discrete_range"
      one_of [:range,:subtype_indication]
      methout()
    end

    #subtype_indication ::= [ resolution_function_name ] type_mark [ constraint ]
    def subtype_indication
      methin "subtype_indication"
      begin
        name1 = resolution_function_name()
        #pp showNext
        if showNext.is_a? [:integer,:natural,:positive,:boolean]
          #pp showNext
          name2=acceptIt
        elsif showNext.is_a? [:identifier]
          name2=type_mark()
        end
        if name2.nil?
          say "type_mark"
          name2,name1=name1,nil
        end
        maybe_one :constraint
      rescue
        say "tried a subtype_indication unsuccessfully"
      end
      methout()
    end

    # def subtype_indication
    #   methin "subtype_indication"
    #   maybe_one :resolution_function_name
    #   type_mark()
    #   maybe_one :constraint
    #   methout()
    # end

    def resolution_function_name
      methin "resolution_function_name"
      if showNext.is_a? :identifier
        name()
      end
      methout()
      nil
    end

    def type_mark
      methin "type_mark"
      #pp showNext
      if showNext.is_a? [:identifier,:boolean,:natural,:integer]
        if showNext.is_a? [:boolean,:natural,:integer]
          acceptIt
          methout()
          return
        end
        ret=name()
        methout()
        return ret # NOT standard : was name (but recursion)
      end
      say "no type_mark"
      methout()
    end

    def constraint
      methin "constraint"
      one_of [:range_constraint,:index_constraint]
      methout()
    end

    def range_constraint
      methin "range_constraint"
      expect :range
      range()
      methout()
    end

    def index_constraint
      methin "index_constraint"
      expect :lparen
      discrete_range()
      several do
        expect :comma
        discrete_range()
      end
      expect :rparen
      methout()
    end

    #range ::=
    #	range_attribute_name
    #	| simple_expression direction simple_expression
    # HERE I needed to switch the two rules...
    def range(d=nil)
      methin "range"
      begin
        simple_expression()
        direction()
        simple_expression()
      rescue
        attribute_name()
      end
      methout()
    end

    def direction(d=nil)
      methin "direction"
      if showNext.is_a? [:to,:downto]
        acceptIt
      end
      methout()
    end

    # # attribute_name ::= prefix [ signature ] ' attribute_designator [ ( expression ) ]
    # def attribute_name
    #   methin "attribute_name"
    #   simple_name() # deviation  should be prefix(), but recursion
    #   begin
    #     signature()
    #   rescue
    #   ensure
    #     expect(:attribute)
    #     if showNext.is_a? :lparen
    #       acceptIt()
    #       expression()
    #       expect :rparen
    #     end
    #   end
    #   methout()
    # end

    def attribute_name
      methin "attribute_name"
      simple_name
      methout
    end

    # ---------------------- expression ---------------------------
    # expression ::=
    #         relation { AND relation }
    #       | relation { OR relation }
    #       | relation { XOR relation }
    #       | relation [ NAND relation ]
    #       | relation [ NOR relation ]
    #       | relation { XNOR relation }
    def expression
      methin "expression"
      relation()
      while showNext.is_a? [:and,:or,:xor,:nand,:nor,:xnor]
        acceptIt
        relation()
      end
      methout()
    end

    def relation
      methin "relation"
      shift_expression()
      if showNext.is_a? [:eq,:neq,:lt,:sassign,:gt,:gte]
        acceptIt
        shift_expression()
      end
      methout()
    end

    def shift_expression
      methin "shift_expression"
      simple_expression()
      if showNext.is_a? [:sll,:srl,:sla,:sra,:rol,:ror]
        acceptIt
        simple_expression()
      end
      methout()
    end

    # simple_expression ::= [ sign ] term { adding_operator term }
    def simple_expression
      methin "simple_expression"
      if showNext.is_a? [:plus,:minus]
        sign=acceptIt
      end

      term()

      while showNext.is_a? [:plus, :minus,:ampersand]
        acceptIt
        term()
      end

      methout()
    end

    def term
      methin "term"
      factor()
      while showNext.is_a? [:mult,:div,:mod,:ram]
        acceptIt
        factor()
      end
      methout()
    end

    def factor
      methin "factor"

      if showNext.is_a? [:abs,:not]
        acceptIt
      end
      primary()
      if showNext.is_a? :doublestar
        acceptIt
        primary()
      end
      methout()
    end

    # primary ::=
    #       name
    #       | literal
    #       | aggregate
    #       | function_call
    #       | qualified_expression
    #       | type_conversion
    #       | allocator
    #       | ( expression )

    def show_following_tokens enable=false
      range=0..5
      puts tokens[range].collect{|tok| tok.val}.join(" ").cyan if enable
    end

    def primary
      methin "primary"
      #show_following_tokens
      rule=one_of [:literal,
              :function_call,
              :aggregate,
              :parenth_expression,
              :name,
              :qualified_expression,
              :type_conversion,
              :allocator]

      methout()
    end

    def parenth_expression
      methin "parenth_expression"
      expect(:lparen)
      expression()
      expect(:rparen)
      methout
    end

    def function_call
      methin "function_call"
      #show_following_tokens
      expect :identifier
      expect :lparen
      expression
      while showNext.is_a? :comma
        acceptIt
        expression
      end
      expect :rparen
      methout()
    end

    # literal ::=
    # 	numeric_literal
    # 	| enumeration_literal
    # 	| string_literal
    # 	| bit_string_literal
    # 	| NULL

    def literal
      methin "literal"
      #show_following_tokens
      if showNext.is_a? [:decimal_literal,:based_literal,:string_literal,:char_literal,:bit_string_literal,:null]
        acceptIt
        if showNext.is_a? :identifier
          say "physical literal"
          unit_name=acceptIt
          if not ["ns","ms","fs","s"].include? unit_name.value
            raise_it "physical time unit error ?"
          end
        end
      else
        raise # was missing !
      end
      #show
      methout()
    end

  end #parser

end #module Vertigo

if $PROGRAM_NAME == __FILE__
  filename=ARGV[0]
  raise "need a file !" if filename.nil?
  puts "argv.size = #{ARGV.size}"
  t1 = Time.now
  parser=Vertigo::Parser.new(verbose: true)
  case ARGV.size
  when 1
    ast=parser.parse(filename)
    pp ast
  when 2 # method name, to apply
    method=ARGV[1].to_sym
    parser.lex filename
    puts "parsing only with method : '#{method}'"
    parser.send(method)
  end
  t2 = Time.now
  puts "compiled in     : #{t2-t1} s"
end
