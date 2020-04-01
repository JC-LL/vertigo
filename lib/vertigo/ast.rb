require_relative "ast_vertigo_rkgen"

module Vertigo

  class AstNode
    attr_accessor :label
    attr_accessor :pos
  end

  class Root < AstNode
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

  class Sensitivity < AstNode
    def << e
      @elements << e
    end
  end

  class EnumDecl < AstNode
    def << e
      @elements << e
    end
  end

  class Case < AstNode
    def << e
      @whens << e
    end
  end

  class Aggregate < AstNode
    def << e
      @elements << e
    end
  end

  class PortMap < AstNode
    def << e
      @elements << e
    end
  end

  class GenericMap < AstNode
    def << e
      @elements << e
    end
  end

end
