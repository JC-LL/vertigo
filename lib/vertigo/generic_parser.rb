class GenericParser

  def acceptIt
    tok=tokens.shift
    puts "consuming #{tok.val} (#{tok.kind})" if @verbose
    tok
  end

  def showNext k=1
    tokens[k-1]
  end

  def expect kind
    if (actual=showNext.kind)!=kind
      abort "ERROR at #{showNext.pos}. Expecting #{kind}. Got #{actual}"
    else
      return acceptIt()
    end
  end

  def maybe kind
    if showNext.kind==kind
      return acceptIt
    end
    nil
  end

  def more?
    !tokens.empty?
  end

  def lookahead n
    showNext(k=n)
  end

  def niy
    raise "NIY"
  end

end
