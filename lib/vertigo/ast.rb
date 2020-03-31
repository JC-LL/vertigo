require_relative "ast_vertigo_rkgen"

module Vertigo

  class AstNode
    attr_accessor :label
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

end
