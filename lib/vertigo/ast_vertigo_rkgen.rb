# ============================================================
# This code was generated by rkgen utility.
# DO NOT MODIFY !
# ============================================================

module Vertigo

  class AstNode
    def accept(visitor, arg=nil)
       name = self.class.name.split(/::/).last
       visitor.send("visit#{name}".to_sym, self ,arg) # Metaprograming !
    end

    def str
      ppr=PrettyPrinter.new
      self.accept(ppr)
    end
  end

  class Root < AstNode
    attr_accessor :design_units
    def initialize design_units=[]
      @design_units=design_units
    end
  end

  class Comment < AstNode
    attr_accessor :str
    def initialize str=nil
      @str=str
    end
  end

  class Library < AstNode
    attr_accessor :name
    def initialize name=nil
      @name=name
    end
  end

  class Use < AstNode
    attr_accessor :library,:package,:element
    def initialize library=nil,package=nil,element=nil
      @library,@package,@element=library,package,element
    end
  end

  class Entity < AstNode
    attr_accessor :name,:generics,:ports
    def initialize name=nil,generics=[],ports=[]
      @name,@generics,@ports=name,generics,ports
    end
  end

  class Generic < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Input < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Output < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class InOut < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Package < AstNode
    attr_accessor :name,:decls
    def initialize name=nil,decls=[]
      @name,@decls=name,decls
    end
  end

  class PackageBody < AstNode
    attr_accessor :name,:decls
    def initialize name=nil,decls=[]
      @name,@decls=name,decls
    end
  end

  class ProcedureDecl < AstNode
    attr_accessor :name,:formal_args,:decls,:body
    def initialize name=nil,formal_args=[],decls=[],body=nil
      @name,@formal_args,@decls,@body=name,formal_args,decls,body
    end
  end

  class FormalArg < AstNode
    attr_accessor :signal,:direction,:name,:type
    def initialize signal=nil,direction=nil,name=nil,type=nil
      @signal,@direction,@name,@type=signal,direction,name,type
    end
  end

  class ProcedureCall < AstNode
    attr_accessor :name,:actual_args
    def initialize name=nil,actual_args=[]
      @name,@actual_args=name,actual_args
    end
  end

  class Architecture < AstNode
    attr_accessor :name,:entity_name,:decls,:body
    def initialize name=nil,entity_name=nil,decls=[],body=nil
      @name,@entity_name,@decls,@body=name,entity_name,decls,body
    end
  end

  class Body < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class Process < AstNode
    attr_accessor :sensitivity,:decls,:body
    def initialize sensitivity=nil,decls=[],body=nil
      @sensitivity,@decls,@body=sensitivity,decls,body
    end
  end

  class Sensitivity < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class EntityInstance < AstNode
    attr_accessor :full_name,:arch_name,:generic_map,:port_map
    def initialize full_name=nil,arch_name=nil,generic_map=nil,port_map=nil
      @full_name,@arch_name,@generic_map,@port_map=full_name,arch_name,generic_map,port_map
    end
  end

  class ComponentDecl < AstNode
    attr_accessor :name,:generics,:ports
    def initialize name=nil,generics=[],ports=[]
      @name,@generics,@ports=name,generics,ports
    end
  end

  class ComponentInstance < AstNode
    attr_accessor :name,:generic_map,:port_map
    def initialize name=nil,generic_map=nil,port_map=nil
      @name,@generic_map,@port_map=name,generic_map,port_map
    end
  end

  class PortMap < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class GenericMap < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class Map < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class AttributeDecl < AstNode
    attr_accessor :name,:type
    def initialize name=nil,type=nil
      @name,@type=name,type
    end
  end

  class AttributeSpec < AstNode
    attr_accessor :name,:entity_spec,:expr
    def initialize name=nil,entity_spec=nil,expr=nil
      @name,@entity_spec,@expr=name,entity_spec,expr
    end
  end

  class EntitySpec < AstNode
    attr_accessor :elements,:entity_class
    def initialize elements=[],entity_class=nil
      @elements,@entity_class=elements,entity_class
    end
  end

  class SigAssign < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class VarAssign < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Wait < AstNode
    attr_accessor :until_,:for_
    def initialize until_=nil,for_=nil
      @until_,@for_=until_,for_
    end
  end

  class If < AstNode
    attr_accessor :cond,:body,:elsifs,:else_
    def initialize cond=nil,body=nil,elsifs=[],else_=nil
      @cond,@body,@elsifs,@else_=cond,body,elsifs,else_
    end
  end

  class Elsif < AstNode
    attr_accessor :cond,:body
    def initialize cond=nil,body=nil
      @cond,@body=cond,body
    end
  end

  class Else < AstNode
    attr_accessor :body
    def initialize body=nil
      @body=body
    end
  end

  class Case < AstNode
    attr_accessor :expr,:whens
    def initialize expr=nil,whens=[]
      @expr,@whens=expr,whens
    end
  end

  class CaseWhen < AstNode
    attr_accessor :expr,:body
    def initialize expr=nil,body=nil
      @expr,@body=expr,body
    end
  end

  class Alternative < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class NullStmt < AstNode
    attr_accessor :dummy
    def initialize dummy=nil
      @dummy=dummy
    end
  end

  class Assert < AstNode
    attr_accessor :cond,:report,:severity
    def initialize cond=nil,report=nil,severity=nil
      @cond,@report,@severity=cond,report,severity
    end
  end

  class Report < AstNode
    attr_accessor :expr,:severity
    def initialize expr=nil,severity=nil
      @expr,@severity=expr,severity
    end
  end

  class Severity < AstNode
    attr_accessor :type
    def initialize type=nil
      @type=type
    end
  end

  class Return < AstNode
    attr_accessor :expr
    def initialize expr=nil
      @expr=expr
    end
  end

  class WithSelect < AstNode
    attr_accessor :with_expr,:assigned,:selected_whens
    def initialize with_expr=nil,assigned=nil,selected_whens=[]
      @with_expr,@assigned,@selected_whens=with_expr,assigned,selected_whens
    end
  end

  class SelectedWhen < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class IfGenerate < AstNode
    attr_accessor :cond,:body
    def initialize cond=nil,body=nil
      @cond,@body=cond,body
    end
  end

  class ForGenerate < AstNode
    attr_accessor :index,:range,:decls,:body
    def initialize index=nil,range=nil,decls=[],body=nil
      @index,@range,@decls,@body=index,range,decls,body
    end
  end

  class IsolatedRange < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class TypeDecl < AstNode
    attr_accessor :name,:spec
    def initialize name=nil,spec=nil
      @name,@spec=name,spec
    end
  end

  class SubTypeDecl < AstNode
    attr_accessor :name,:spec
    def initialize name=nil,spec=nil
      @name,@spec=name,spec
    end
  end

  class EnumDecl < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class RecordDecl < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class RecordItem < AstNode
    attr_accessor :name,:type
    def initialize name=nil,type=nil
      @name,@type=name,type
    end
  end

  class ArrayDecl < AstNode
    attr_accessor :dim_decls,:type
    def initialize dim_decls=[],type=nil
      @dim_decls,@type=dim_decls,type
    end
  end

  class ArrayDimDecl < AstNode
    attr_accessor :type_mark,:range
    def initialize type_mark=nil,range=nil
      @type_mark,@range=type_mark,range
    end
  end

  class Constant < AstNode
    attr_accessor :name,:type,:expr
    def initialize name=nil,type=nil,expr=nil
      @name,@type,@expr=name,type,expr
    end
  end

  class Signal < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Variable < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Alias < AstNode
    attr_accessor :designator,:type,:name,:signature
    def initialize designator=nil,type=nil,name=nil,signature=nil
      @designator,@type,@name,@signature=designator,type,name,signature
    end
  end

  class StdType < AstNode
    attr_accessor :ident
    def initialize ident=nil
      @ident=ident
    end
  end

  class RangedType < AstNode
    attr_accessor :type,:range
    def initialize type=nil,range=nil
      @type,@range=type,range
    end
  end

  class NamedType < AstNode
    attr_accessor :ident
    def initialize ident=nil
      @ident=ident
    end
  end

  class ArrayType < AstNode
    attr_accessor :name,:discrete_ranges
    def initialize name=nil,discrete_ranges=[]
      @name,@discrete_ranges=name,discrete_ranges
    end
  end

  class DiscreteRange < AstNode
    attr_accessor :lhs,:dir,:rhs
    def initialize lhs=nil,dir=nil,rhs=nil
      @lhs,@dir,@rhs=lhs,dir,rhs
    end
  end

  class Parenth < AstNode
    attr_accessor :expr
    def initialize expr=nil
      @expr=expr
    end
  end

  class Waveform < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class CondExpr < AstNode
    attr_accessor :whens,:else_
    def initialize whens=[],else_=nil
      @whens,@else_=whens,else_
    end
  end

  class When < AstNode
    attr_accessor :expr,:cond
    def initialize expr=nil,cond=nil
      @expr,@cond=expr,cond
    end
  end

  class Binary < AstNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs=nil,op=nil,rhs=nil
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class After < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Timed < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Attributed < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Concat < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Qualified < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Sliced < AstNode
    attr_accessor :expr,:lhs,:dir,:rhs
    def initialize expr=nil,lhs=nil,dir=nil,rhs=nil
      @expr,@lhs,@dir,@rhs=expr,lhs,dir,rhs
    end
  end

  class Ident < AstNode
    attr_accessor :tok
    def initialize tok=nil
      @tok=tok
    end
  end

  class IntLit < AstNode
    attr_accessor :tok
    def initialize tok=nil
      @tok=tok
    end
  end

  class CharLit < AstNode
    attr_accessor :tok
    def initialize tok=nil
      @tok=tok
    end
  end

  class BoolLit < AstNode
    attr_accessor :tok
    def initialize tok=nil
      @tok=tok
    end
  end

  class SelectedName < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class FuncProtoDecl < AstNode
    attr_accessor :name,:formal_args,:return_type
    def initialize name=nil,formal_args=[],return_type=nil
      @name,@formal_args,@return_type=name,formal_args,return_type
    end
  end

  class FuncDecl < AstNode
    attr_accessor :name,:formal_args,:return_type,:decls,:body
    def initialize name=nil,formal_args=[],return_type=nil,decls=nil,body=nil
      @name,@formal_args,@return_type,@decls,@body=name,formal_args,return_type,decls,body
    end
  end

  class FuncCall < AstNode
    attr_accessor :name,:actual_args
    def initialize name=nil,actual_args=[]
      @name,@actual_args=name,actual_args
    end
  end

  class Aggregate < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class Label < AstNode
    attr_accessor :ident
    def initialize ident=nil
      @ident=ident
    end
  end

  class Assoc < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end
end # Vertigo
