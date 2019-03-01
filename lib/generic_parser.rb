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
      abort "ERROR at #{showNext.pos}. Expecting #{kind}. Got #{actual}" if @verbose
      exit
    else
      return acceptIt()
    end
  end

  def more?
    !tokens.empty?
  end

end
