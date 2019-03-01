module Vertigo

  class Ast
  end

  class Root < Ast
    attr_accessor :elements
    def initialize
      @elements=[]
    end

    def <<(e)
      @elements << e
    end
  end

  class Comment < Ast
    def initialize e
      @tokens=[e]
    end

    def <<(e)
      @tokens << e
    end
  end

  class DesignUnit < Ast
    attr_accessor :context_clause
    attr_accessor :library_unit
  end

  class ContextClause < Ast
    def initialize
      @items=[]
    end

    def <<(e)
      @items << e
    end
  end

  class LibraryClause < Ast
    attr_accessor :name_list
    def initialize
      @name_list=[]
    end

    def <<(e)
      @name_list << e
    end
  end

  class UseClause < Ast
    attr_accessor :selected_name_list
    def initialize
      @selected_name_list=[]
    end

    def <<(e)
      @selected_name_list << e
    end
  end

  class Entity < Ast
    attr_accessor :name
    attr_accessor :generics
    attr_accessor :ports
    def initialize
      @generics=[]
      @ports=[]
    end
  end

  class Declaration < Ast
    attr_accessor :ident
    attr_accessor :mode
    attr_accessor :type
    attr_accessor :init
  end

  class Architecture < Ast
    attr_accessor :name
    attr_accessor :entity
    attr_accessor :declarations
    attr_accessor :body
  end

  # expressions
  class Ident < Ast
    attr_accessor :token
    def initialize tok
      @token=tok
    end
  end

end
