module Indent

  INDENT=2

  def indent str
    @indentation||=-INDENT
    @indentation+=INDENT
    say(str)
  end

  def dedent
    @indentation-=INDENT
  end

  def say str
    @indentation||=0
    puts " "*@indentation+str if @verbose
  end

end
