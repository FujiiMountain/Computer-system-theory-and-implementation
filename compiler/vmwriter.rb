class VMWriter

  def initialize(filename)
    @writeFile = File.open(filename, "w")
  end

  def writePush(segment, index)
    @writeFile.puts "push #{segment.downcase} #{index}"
  end

  def writePop(segment, index)
    @writeFile.puts "pop #{segment.downcase} #{index}"
  end

  def writeArithmetic(command)
    @writeFile.puts "#{command.downcase}"
  end

  def writeLabel(label)
    @writeFile.puts "label #{label.upcase}"
  end

  def writeGoto(label)
    @writeFile.puts "goto #{label.upcase}"
  end

  def writeIf(label)
    @writeFile.puts "if-goto #{label.upcase}"
  end

  def writeCall(name, nArgs)
    @writeFile.puts "call #{name} #{nArgs}"
  end

  def writeFunction(name, nLocals)
    @writeFile.puts "function #{name} #{nLocals}"
  end

  def writeReturn
    @writeFile.puts "return"
  end

  def close
    @writeFile.close
  end
end
