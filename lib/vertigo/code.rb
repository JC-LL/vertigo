class Code

  attr_accessor :indent,:lines

  def initialize str=nil
    @lines=[]
    (@lines << str) if str
    @indent=0
  end

  def <<(thing)
    if (code=thing).is_a? Code
      code.lines.each do |line|
        @lines << " "*@indent+line.to_s
      end
    elsif thing.is_a? Array
      thing.each do |kode|
        @lines << kode
      end
    elsif thing.nil?
    else
      @lines << " "*@indent+thing.to_s
    end
  end

  def finalize
    str=@lines.join("\n") if @lines.any?
    str=clean(str)
    return str if @lines.any?
    ""
  end

  def clean str
    str=str.gsub(/;[\s\n]*;/ ,';')
    str=str.gsub(/;[\s\n]*\)/ ,')')
    str=str.gsub(/,[\s\n]*\)/,')')
  end

  def newline
    @lines << " "
  end

  def save_as filename,verbose=true
    str=self.finalize
    File.open(filename,'w'){|f| f.puts(str)}
    return filename
  end

  def size
    @lines.size
  end

  def last
    @lines.last
  end

end
