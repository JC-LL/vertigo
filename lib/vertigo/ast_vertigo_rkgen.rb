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
   
  class Architecture < AstNode
    attr_accessor :name,:entity_name,:decls,:body
    def initialize name=nil,entity_name=nil,decls=[],body=nil
      @name,@entity_name,@decls,@body=name,entity_name,decls,body
    end
  end
   
  class Ident < AstNode
    attr_accessor :token
    def initialize token=nil
      @token=token
    end
  end
end # Vertigo
