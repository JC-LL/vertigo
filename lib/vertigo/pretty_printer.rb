require_relative 'code'

module Vertigo

  class PrettyPrinter

    def print ast
      begin
        puts "print"
        code=Code.new
        code << "-- generated by Vertigo VHDL tool"
        code << ast.accept(self)
        code
        puts code.finalize
      rescue Exception => e
        puts e.backtrace
        puts e
      end
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
      code << "port("
      code.indent=4
      entity.ports.each{|port_| code << port_.accept(self,args)}
      code.indent=2
      code << ");"
      code.indent=0
      code << "end entity #{name};"
      code.newline
      code
    end

    def visitGeneric(generic,args=nil)
      name=generic.name.accept(self,args)
      type=generic.type.accept(self,args)
      init=generic.init.accept(self,args) if generic.init
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
      init=inout.init.accept(self,args)
      "#{name} : inout #{type}#{init};"
    end

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
      code.indent=2
      code << body
      code.indent=0
      code << "end #{name};"
      code
    end

    def visitSignal signal,args=nil
      name=signal.name.accept(self)
      type=signal.type.accept(self)
      init=signal.init.accept(self) if signal.init
      init=" := #{init}" if init
      "signal #{name} : #{type}#{init};"
    end

    def visitBody(body,args=nil)
      code=Code.new
      body.elements.each{|element_| code << element_.accept(self,args)}
      code
    end

    def visitLabel label,args=nil
      id=label.ident.accept(self)
      "#{id}:"
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

    def visitProcess(process,args=nil)
      code=Code.new
      label=process.label.accept(self) if process.label
      sensitity=process.sensitivity.accept(self,args) if process.sensitivity
      sensitity="(#{sensitity})" if sensitity
      process.decls.each{|decl_| decl_.accept(self,args)}
      body=process.body.accept(self,args)
      code.newline
      code << "#{label}process#{sensitity}"
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

    def visitSigAssign(sigassign,args=nil)
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
      "(#{lhs} #{op} #{rhs})"
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

    def visitFuncCall funcall,arfgs=nil
      name=funcall.name.accept(self)
      args=funcall.actual_args.map{|arg| arg.accept(self)}.join(',')
      "#{name}(#{args})"
    end

  end
end
