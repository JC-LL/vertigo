require_relative "ast_vertigo_rkgen"

module Vertigo

    class AstNode
    end

    class Root
      def <<(e)
        @design_units << e
      end

      def flatten!
        @design_units.flatten!
      end
    end

    class Body < AstNode
      def <<(e)
        @elements << e
      end
    end

    class Expression < AstNode
    end

    class Binary < Expression
      attr_accessor :lhs,:op,:rhs
      def initialize lhs=nil,op=nil,rhs=nil
        @lhs,@op,@rhs=lhs,op,rhs
      end
    end

    class FuncCall
      attr_accessor :name,:actual_args
      def initialize name=nil,args=[]
        @name,@args=name,args
      end
    end

    class Timed
      attr_accessor :lhs,:rhs
      def initialize lhs,rhs
        @lhs,@rhs=lhs,rhs
      end
    end
end
