class Token
  attr_accessor :kind,:val,:pos
  def initialize tab
    @kind,@val,@pos=*tab
  end

  def is_a? kind
    case kind
    when Symbol
      return @kind==kind
    when Array
      for sym in kind
        return true if @kind==sym
      end
      return false
    else
      raise "wrong type during lookahead"
    end
  end

  alias :value :val

  def accept visitor
  end

  def self.create str
    Token.new [:id,str,[0,0]]
  end

  def inspect
    "(token #{kind} '#{val}' #{pos})"
  end
end

ONE  = Token.new [:int_lit,'1',['na','na']]
ZERO = Token.new [:int_lit,'0',['na','na']]
DUMMY= Token.new [:id     ,'' ,['na','na']]
