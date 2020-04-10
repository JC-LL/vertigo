require_relative 'code'

module Vertigo

  class PrettyPrinter

    def print ast
      code=Code.new
      code << "-- generated by Vertigo VHDL tool"
      code << ast.accept(self)
      code
    end

    def visitRoot(root,args=nil)
      code=Code.new
      root.design_units.each{|design_unit_| code << design_unit_.accept(self,args)}
      code
    end

    def visitLibrary(library,args=nil)
      name=library.name.accept(self,args)
      "library #{name};"
    end

    def visitUse(use,args=nil)
      library=use.library.accept(self,args)
      package=use.package.accept(self,args)
      element=use.element.accept(self,args)
      "use #{library}.#{package}.#{element};"
    end

    def visitEntity(entity,args=nil)
      code=Code.new
      name=entity.name.accept(self,args)
      code.newline
      code << "entity #{name} is"
      code.indent=2
      if entity.generics.any?
        code << "generic("
        code.indent=4
        entity.generics.each{|generic_| code << generic_.accept(self,args)}
        code.indent=2
        code << ");"
      end
      if entity.ports.any?
        code << "port("
        code.indent=4
        entity.ports.each{|port_| code << port_.accept(self,args)}
        code.indent=2
        code << ");"
      end
      code.indent=0
      code << "end entity #{name};"
      code.newline
      code
    end

    def visitGeneric(generic,args=nil)
      name=generic.name.accept(self,args)
      type=generic.type.accept(self,args)
      init=generic.init.accept(self,args) if generic.init
      init+=" := #{init}" if init
      "#{name} : #{type}#{init};"
    end

    def visitInput(input,args=nil)
      name=input.name.accept(self,args)
      type=input.type.accept(self,args)
      init=input.init.accept(self,args) if input.init
      "#{name} : in #{type}#{init};"
    end

    def visitOutput(output,args=nil)
      name=output.name.accept(self,args)
      type=output.type.accept(self,args)
      init=output.init.accept(self,args) if output.init
      "#{name} : out #{type}#{init};"
    end

    def visitInOut(inout,args=nil)
      name=inout.name.accept(self,args)
      type=inout.type.accept(self,args)
      init=inout.init.accept(self,args) if inout.init
      "#{name} : inout #{type}#{init};"
    end

    # ====================================================
    def visitPackage package_,args=nil
      name=package_.name.accept(self,args)
      code=Code.new
      code.newline
      code << "package #{name} is"
      code.indent=2
      code.newline
      package_.decls.each{|decl_| code << decl_.accept(self,args)}
      code.indent=0
      code << "end #{name};"
      code.newline
      code
    end

    def visitPackageBody(packagebody_,args=nil)
      name=packagebody_.name.accept(self,args)
      code=Code.new
      code << "package body #{name} is"
      code.indent=2
      packagebody_.decls.each{|decl_| code << decl_.accept(self,args)}
      code.indent=0
      code << "end #{name};"
      code
    end

    def visitProcedureDecl(proceduredecl_,args=nil)
      name=proceduredecl_.name.accept(self,args)
      code=Code.new
      code.newline
      code << "procedure #{name}("
      code.indent=2
      proceduredecl_.formal_args.map{|formal_arg_| code << formal_arg_.accept(self,args)+";"}
      code.indent=0
      code.last << ")"
      if proceduredecl_.decls.any? or !proceduredecl_.body.nil?
        code.last << " is"
        decls=proceduredecl_.decls.each{|decl_| decl_.accept(self,args)}
        body =proceduredecl_.body.accept(self,args) if proceduredecl_.body
        code.indent=2
        code << decls
        code.indent=0
        code << "begin"
        code.indent=2
        code << body
        code.indent=0
        code << "end #{name};"
      else
        code.last << ";"
      end
      code
    end

    def visitFormalArg formalarg_,args=nil
      sig =formalarg_.signal.accept(self,args) if formalarg_.signal
      dir =formalarg_.direction.accept(self,args) if formalarg_.direction
      dir+=" " if dir
      name=formalarg_.name.accept(self,args)
      type=formalarg_.type.accept(self,args)
      "#{sig}#{name} : #{dir}#{type}"
    end

    def visitProcedureCall(procedurecall_,args=nil)
      name=procedurecall_.name.accept(self,args)
      args=name=procedurecall_.actual_args.map{|actual_arg_| actual_arg_.accept(self,args)}.join(',')
      args="(#{args})" if args
      "#{name}#{args}"
    end

    # ====================================================
    def visitArchitecture(architecture,args=nil)
      code=Code.new
      name=architecture.name.accept(self,args)
      entity_name=architecture.entity_name.accept(self,args)
      body=architecture.body.accept(self,args)

      code << "architecture #{name} of #{entity_name} is"
      code.indent=2
      architecture.decls.each{|decl_| code << decl_.accept(self,args)}
      code.indent=0
      code << "begin"
      code.newline
      code.indent=2
      code << body
      code.indent=0
      code << "end #{name};"
      code
    end

    def visitTypeDecl type_decl,args=nil
      name=type_decl.name.accept(self)
      type_spec=type_decl.spec.accept(self)
      code=Code.new
      code.newline
      code << "type #{name} is #{type_spec};"
      code
    end

    def visitSubTypeDecl sub_type_decl,args=nil
      name=sub_type_decl.name.accept(self)
      type_spec=sub_type_decl.spec.accept(self)
      code=Code.new
      code.newline
      code << "subtype #{name} is #{type_spec};"
      code
    end

    def visitEnumDecl enum,args=nil
      elems=enum.elements.map{|e| e.accept(self)}
      "(#{elems.join(',')})"
    end

    def visitRecordDecl rec,args=nil
      code=Code.new
      code << "record"
      code.indent=4
      rec.elements.map{|e| code << e.accept(self)}
      code.indent=2
      code << "end record"
      code.finalize
    end

    def visitRecordItem ri,args=nil
      name=ri.name.accept(self)
      type=ri.type.accept(self)
      "#{name} : #{type};"
    end

    def visitArrayDecl(arraydecl_,args=nil)
      ranges=arraydecl_.dim_decls.map{|dim_decl_| dim_decl_.accept(self,args)}
      type=arraydecl_.type.accept(self)
      "array(#{ranges.join(',')}) of #{type}"
    end

    def visitArrayDimDecl(arraydimdecl_,args=nil)
      type_mark=arraydimdecl_.type_mark.accept(self)+" " if arraydimdecl_.type_mark
      range=arraydimdecl_.range.accept(self,args)
      "#{type_mark}range #{range}"
    end

    def visitConstant cst,args=nil
      name=cst.name.accept(self)
      type=cst.type.accept(self)
      expr=cst.expr.accept(self)
      "constant #{name} : #{type} := #{expr};"
    end

    def visitSignal signal,args=nil
      name=signal.name.accept(self)
      type=signal.type.accept(self)
      init=signal.init.accept(self) if signal.init
      init=" := #{init}" if init
      "signal #{name} : #{type}#{init};"
    end

    def visitVariable variable,args=nil
      name=variable.name.accept(self)
      type=variable.type.accept(self)
      init=variable.init.accept(self) if variable.init
      init=" := #{init}" if init
      "variable #{name} : #{type}#{init};"
    end

    def visitAlias(alias_,args=nil)
      designator= alias_.designator.accept(self,args)
      type      = alias_.type.accept(self,args)
      name      = alias_.name.accept(self,args)
      signature = alias_.signature.accept(self,args) if alias_.signature
      "alias #{designator} : #{type} is #{name} #{};"
    end

    def visitBody(body,args=nil)
      code=Code.new
      body.elements.each{|element_| code << element_.accept(self,args)}
      code
    end

    def visitLabel label,args=nil
      id=label.ident.accept(self)
      "#{id} : "
    end

    def visitIf if_,args=nil
      label=if_.label.accept(self) if if_.label
      cond=if_.cond.accept(self)
      body=if_.body.accept(self)
      elsifs_=if_.elsifs.map{|elsif_| elsif_.accept(self)}
      else_=if_.else_.accept(self) if if_.else_
      code=Code.new
      code << "#{label}if #{cond} then"
      code.indent=2
      code << body
      code.indent=0
      if if_.elsifs.any?
        elsifs_.each{|elsif_| code << elsif_}
      end
      if if_.else_
        code << else_
      end
      code << "end if;"
      code
    end

    def visitElsif elsif_,args=nil
      cond=elsif_.cond.accept(self)
      body=elsif_.body.accept(self)
      code=Code.new
      code << "elsif #{cond} then"
      code.indent=2
      code << body
      code.indent=0
      code
    end

    def visitElse else_,args=nil
      body=else_.body.accept(self)
      code=Code.new
      code << "else"
      code.indent=2
      code << body
      code
    end

    def visitCase case_,args=nil
      expr=case_.expr.accept(self)
      whens=case_.whens.map{|when_| when_.accept(self)}
      code=Code.new
      code << "case #{expr} is"
      code.indent=2
      case_.whens.map{|when_| code << when_.accept(self)}
      code.indent=0
      code << "end case;"
      code
    end

    def visitCaseWhen cwhen,args=nil
      expr=cwhen.expr.accept(self)
      body=cwhen.body.accept(self)
      code=Code.new
      code << "when #{expr} =>"
      code.indent=2
      code << body
      code.indent=0
      code
    end

    def visitAlternative(alternative_,args=nil)
      alternative_.elements.map{|element_| element_.accept(self,args)}.join(" | ")
    end

    def visitNullStmt null_,args=nil
      "null;"
    end

    def visitAssert assert,args=nil
      cond=assert.cond.accept(self)
      repo=assert.report.accept(self) if assert.report
      code=Code.new
      code << "assert #{cond}"
      code.indent=2
      code << repo if repo
      code.indent=0
      code.last << ";"
      code
    end

    def visitReport report,args=nil
      expr=report.expr.accept(self)
      sevr=report.severity.accept(self) if report.severity
      severity=" severity #{sevr}" if sevr
      "report #{expr}#{severity};"
    end

     def visitReturn(return_,args=nil)
       expr=return_.expr.accept(self,args) if return_.expr
       expr=" #{expr}" if expr
       "return#{expr};"
     end

    def visitWithSelect(withselect_,args=nil)
      expr=withselect_.with_expr.accept(self,args)
      assigned=withselect_.assigned.accept(self,args)

      code=Code.new
      code << "with #{expr} select #{assigned} <="
      code.indent=2
      withselect_.selected_whens.each{|selected_when_| code << selected_when_.accept(self,args)+","}
      code.indent=0
      code.last << ";"
      code
    end

    def visitSelectedWhen(selectedwhen_,args=nil)
      lhs=selectedwhen_.lhs.accept(self,args)
      rhs=selectedwhen_.rhs.accept(self,args)
      "#{lhs} when #{rhs}"
    end

    def visitIfGenerate(ifgenerate_,args=nil)
      cond=ifgenerate_.cond.accept(self,args)
      body=ifgenerate_.body.accept(self,args)
      code=Code.new
      code << "if #{cond} generate"
      code.indent=2
      code << body
      code.indent=0
      code << "end generate;"
      code
    end

    def visitForGenerate(forgenerate_,args=nil)
      idx  =forgenerate_.index.accept(self,args)
      range=forgenerate_.range.accept(self,args)
      decls=forgenerate_.decls.each{|decl_| decl_.accept(self,args)} if forgenerate_.decls
      body =forgenerate_.body.accept(self,args)
      code=Code.new
      code << "for #{idx} in #{range} generate"
      code.indent=2
      code << decls if decls
      code << body
      code.indent=0
      code << "end generate;"
      code
    end

    #====================================
    def visitEntityInstance inst,args=nil
      code=Code.new
      label=inst.label.accept(self) if inst.label
      full_name=inst.full_name.accept(self)
      arch_name=inst.arch_name.accept(self) if inst.arch_name
      gen_map  =inst.generic_map.accept(self) if inst.generic_map
      port_map =inst.port_map.accept(self) if inst.port_map
      code << "#{label}entity #{full_name}#{arch_name}"
      code.indent=2
      code << port_map
      code.indent=0
      code.newline
      code
    end

    def visitPortMap port_map,args=nil
      code=Code.new
      code << "port map("
      code.indent=2
      port_map.elements.each{|e| code << e.accept(self)+","}
      code.indent=0
      code << ");"
      code
    end

    def visitMap map,args=nil
      lhs=map.lhs.accept(self)
      rhs=map.rhs.accept(self) if map.rhs
      rhs=" => #{rhs}" if rhs
      "#{lhs}#{rhs}"
    end

    def visitAttributeDecl(attributedecl_,args=nil)
      name=attributedecl_.name.accept(self,args)
      type=attributedecl_.type.accept(self,args)
      "attribute #{name} : #{type};"
    end

    def visitAttributeSpec(attributespec_,args=nil)
      name       =attributespec_.name.accept(self,args)
      entity_spec=attributespec_.entity_spec.accept(self,args)
      expr       =attributespec_.expr.accept(self,args)
      "attribute #{name} of #{entity_spec} is #{expr};"
    end

    def visitEntitySpec(entityspec_,args=nil)
      elements=entityspec_.elements.map{|element_| element_.accept(self,args)}
      entity_class=entityspec_.entity_class.accept(self,args)
      "#{elements.join(',')} : #{entity_class}"
    end

    def visitGenericMap generic_map,args=nil
      code=Code.new
      code << "generic map("
      code.indent=2
      generic_map.elements.each{|e| code << e.accept(self)+","}
      code.indent=0
      code << ");"
      code
    end

    def visitProcess(process,args=nil)
      code=Code.new
      code.newline
      label=process.label.accept(self) if process.label
      sensitity=process.sensitivity.accept(self,args) if process.sensitivity
      sensitity="(#{sensitity})" if sensitity
      body=process.body.accept(self,args)
      code << "#{label}process#{sensitity}"
      code.indent=2
      process.decls.each{|decl_| code << decl_.accept(self,args)}
      code.indent=0
      code << "begin"
      code.indent=2
      code << body
      code.indent=0
      code << "end process;"
      code
    end

    def visitSensitivity(sensitivity,args=nil)
      list=sensitivity.elements.map{|element_| element_.accept(self,args)}
      list.join(',')
    end

    def visitComponentDecl(componentdecl_,args=nil)
      name=componentdecl_.name.accept(self,args)
      code=Code.new
      code << "component #{name} is"
      code.indent=2
      if componentdecl_.generics.any?
        code.indent=4
        code << "generic("
        code.indent=6
        componentdecl_.generics.map{|generic_| code << generic_.accept(self,args)}
        code.indent=4
        code << ");"
        code.indent=2
      end
      code << "port("
      code.indent=6
      componentdecl_.ports.each{|port_| code << port_.accept(self,args)}
      code.indent=4
      code << ");"
      code.indent=0
      code << "end component;"
      code
    end

    def visitComponentInstance(componentinstance_,args=nil)
      label    = componentinstance_.label.accept(self) if componentinstance_.label
      name     = componentinstance_.name.accept(self,args)
      gen_map  = componentinstance_.generic_map.accept(self,args) if componentinstance_.generic_map
      port_map = componentinstance_.port_map.accept(self,args)
      code=Code.new
      code << "#{label}component #{name}"
      code.indent=2
      code << gen_map if gen_map
      code << port_map
      code.indent=0
      code.newline
      code
    end

    def visitSigAssign(sigassign,args=nil)
      #pp sigassign
      lhs=sigassign.lhs.accept(self,args)
      rhs=sigassign.rhs.accept(self,args)
      "#{lhs} <= #{rhs};"
    end

    def visitVarAssign(varassign,args=nil)
      lhs=varassign.lhs.accept(self,args)
      rhs=varassign.rhs.accept(self,args)
      "#{lhs} := #{rhs};"
    end

    def visitWait(wait,args=nil)
      expr=wait.until_.accept(self,args) if wait.until_
      expr=wait.for_.accept(self,args) if wait.for_
      "wait #{expr};"
    end

    def visitStdType(stdtype,args=nil)
      stdtype.ident.accept(self,args)
    end

    def visitRangedType(rangedtype_,args=nil)
      type=rangedtype_.type.accept(self,args)
      range=rangedtype_.range.accept(self,args)
      "#{type} range #{range}"
    end

    def visitNamedType(namedtype,args=nil)
      namedtype.ident.accept(self,args)
    end

    def visitArrayType(arraytype,args=nil)
      name=arraytype.name.accept(self,args)
      ranges=[]
      arraytype.discrete_ranges.each{|discrete_range_| ranges << discrete_range_.accept(self,args)}
      "#{name}(#{ranges.join(',')})"
    end

    def visitDiscreteRange(discreterange,args=nil)
      lhs=discreterange.lhs.accept(self,args)
      dir=discreterange.dir.accept(self,args)
      rhs=discreterange.rhs.accept(self,args)
      "#{lhs} #{dir} #{rhs}"
    end

    def visitWaveform(waveform,args=nil)
      elements=waveform.elements.map{|element_| element_.accept(self,args)}
      elements.join(',')
    end

    def visitCondExpr(condexpr,args=nil)
      code=Code.new
      whens=condexpr.whens.map{|when_| when_.accept(self,args)}
      else_=condexpr.else_.accept(self,args)
      code << "#{whens.join} #{else_}"
      code.finalize
    end

    def visitWhen(when_,args=nil)
      expr=when_.expr.accept(self,args)
      cond=when_.cond.accept(self,args)
      "#{expr} when #{cond} else "
    end

    def visitBinary(binary_,args=nil)
      lhs=binary_.lhs.accept(self,args)
      op=binary_.op.accept(self,args)
      rhs=binary_.rhs.accept(self,args)
      "#{lhs} #{op} #{rhs}"
    end

    def visitIdent(ident,args=nil)
      ident.tok.accept(self,args)
    end

    def visitIntLit(intlit,args=nil)
      intlit.tok.accept(self,args)
    end

    def visitSelectedName(selectedname,args=nil)
      lhs=selectedname.lhs.accept(self,args)
      rhs=selectedname.rhs.accept(self,args)
      "#{lhs}.#{rhs}"
    end

    def visitAfter after,args=nil
      lhs=after.lhs.accept(self,args)
      rhs=after.rhs.accept(self,args)
      "#{lhs} after #{rhs}"
    end

    def visitTimed(timed,args=nil)
      lhs=timed.lhs.accept(self,args)
      rhs=timed.rhs.accept(self,args)
      "#{lhs} #{rhs}"
    end

    def visitAttributed(attributed_,args=nil)
      lhs=attributed_.lhs.accept(self,args)
      rhs=attributed_.rhs.accept(self,args)
      "#{lhs}#{rhs}"
    end

    def visitConcat(concat_,args=nil)
      lhs=concat_.lhs.accept(self,args)
      rhs=concat_.rhs.accept(self,args)
      "#{lhs} & #{rhs}"
    end

    def visitQualified(qualified_,args=nil)
      lhs=qualified_.lhs.accept(self,args)
      rhs=qualified_.rhs.accept(self,args)
      "#{lhs}'#{rhs}"
    end

    def visitSliced(sliced_,args=nil)
      exp=sliced_.expr.accept(self,args)
      lhs=sliced_.lhs.accept(self,args)
      dir=sliced_.dir.accept(self,args)
      rhs=sliced_.rhs.accept(self,args)
      "#{exp}(#{lhs} #{dir} #{rhs})"
    end

    def visitFuncProtoDecl(funcprotodecl_,args=nil)
      name=funcprotodecl_.name.accept(self,args)
      args=funcprotodecl_.formal_args.map{|formal_arg_| formal_arg_.accept(self,args)}.join(";")
      type=funcprotodecl_.return_type.accept(self)
      args="(#{args})" if args
      "function #{name}#{args} return #{type}"
    end

    def visitFuncDecl(funcdecl_,args=nil)
      name=funcdecl_.name.accept(self,args)
      args=funcdecl_.formal_args.map{|formal_arg_| formal_arg_.accept(self,args)}.join(";")
      type=funcdecl_.return_type.accept(self)
      args="(#{args})" if args
      code=Code.new
      code.newline
      code << "function #{name}#{args} return #{type} is"
      code.indent=2
      funcdecl_.decls.each{|decl| code << decl.accept(self)}
      code.indent=0
      code << "begin"
      code.indent=2
      code << funcdecl_.body.accept(self)
      code.indent=0
      code << "end function #{name};"
      code
    end

    def visitFuncCall funcall,args=nil
      name=funcall.name.accept(self)
      args=funcall.actual_args.map{|arg| arg.accept(self)}.join(',')
      "#{name}(#{args})"
    end

    def visitParenth parenth,args=nil
      expr=parenth.expr.accept(self)
      "(#{expr})"
    end

    def visitAggregate aggregate,args=nil
      elems=(elements=aggregate.elements).map{|e| e.accept(self)}
      # here we prototype a multiline method, for long aggregates
      ret="(#{elems.join(',')})"
      if ret.size>40
        klasses=elements.map{|e| e.class}
        if klasses.include?(Aggregate)
          code=Code.new
          code << '('
          code.indent=col=aggregate.pos.last #given by parser.
          elements.each{|e| code << e.accept(self)+","}
          code.indent=col-2
          code << ")"
          ret=code.finalize
        end
      end
      ret
    end

    def visitAssoc assoc,args=nil
      lhs=assoc.lhs.accept(self)
      rhs=assoc.rhs.accept(self)
      "(#{lhs} => #{rhs})"
    end

  end
end
