require './parse.rb'
require './codewriter.rb'

type = 1
filename = "SimpleFunction"
#directoryname = "FibonacciElement"
directoryname = "StaticsTest"

if type == 0
  vmfilename = "./#{filename}.vm"
  asmfilename = "./#{filename}.asm"
  name = vmfilename
  asmcode = CodeWriter.new(asmfilename)
else
  vmdirectoryname = "./#{directoryname}"
  asmdirectoryname = "./#{directoryname}/#{directoryname}.asm"
  directorynames = []
  Dir::foreach(vmdirectoryname) do |f|
    puts f
    name = f.match(/[\w*|\.*|\$*|\-*]+(.vm){1}/).to_s.gsub(/\s/,"").to_s
    if name != ""
      directorynames << vmdirectoryname + "/" + name
    end
  end
  puts directorynames
  asmcode = CodeWriter.new(asmdirectoryname)
end

asmcode.writeInit

puts "開始"

if type == 0
  asmcode.setFileName(vmfilename)
  i = 0
  #VMコードデータ抽出
  vmcode = Parse.new(vmfilename)
  #1行ずつ変換していく
  vmcode.data.each do |vc|
    if vmcode.commandType == "C_ARITHMETIC"
      asmcode.writeArithmetic(vmcode.commandHead)
    elsif vmcode.commandType == "C_PUSH"
      asmcode.writePushPop(vmcode.commandType, vmcode.arg1, vmcode.arg2.to_i)
    elsif vmcode.commandType == "C_POP"
      asmcode.writePushPop(vmcode.commandType, vmcode.arg1, vmcode.arg2.to_i)
    elsif vmcode.commandType == "C_LABEL"
      asmcode.writeLabel(vmcode.arg1)
    elsif vmcode.commandType == "C_GOTO"
      asmcode.writeGoto(vmcode.arg1)
    elsif vmcode.commandType == "C_IF"
      asmcode.writeIf(vmcode.arg1)
    elsif vmcode.commandType == "C_CALL"
      asmcode.writeCall(vmcode.arg1, vmcode.arg2)
    elsif vmcode.commandType == "C_RETURN"
      asmcode.writeReturn
    elsif vmcode.commandType == "C_FUNCTION"
      asmcode.writeFunction(vmcode.arg1, vmcode.arg2)
    end
    i = i+1
    puts i
    puts "vmcode.commandType #{vmcode.commandType}"
    puts "vmcode.arg1 #{vmcode.arg1}"
    puts "vmcode.arg2 #{vmcode.arg2}"
    vmcode.advance
  end
else
  directorynames.each do |vmfilename|
    asmcode.setFileName(vmfilename)
    i = 0
    #VMコードデータ抽出
    vmcode = Parse.new(vmfilename)
    #1行ずつ変換していく
    vmcode.data.each do |vc|
      if vmcode.commandType == "C_ARITHMETIC"
        asmcode.writeArithmetic(vmcode.commandHead)
      elsif vmcode.commandType == "C_PUSH"
        asmcode.writePushPop(vmcode.commandType, vmcode.arg1, vmcode.arg2.to_i)
      elsif vmcode.commandType == "C_POP"
        asmcode.writePushPop(vmcode.commandType, vmcode.arg1, vmcode.arg2.to_i)
      elsif vmcode.commandType == "C_LABEL"
        asmcode.writeLabel(vmcode.arg1)
      elsif vmcode.commandType == "C_GOTO"
        asmcode.writeGoto(vmcode.arg1)
      elsif vmcode.commandType == "C_IF"
        asmcode.writeIf(vmcode.arg1)
      elsif vmcode.commandType == "C_CALL"
        asmcode.writeCall(vmcode.arg1, vmcode.arg2)
      elsif vmcode.commandType == "C_RETURN"
        asmcode.writeReturn
      elsif vmcode.commandType == "C_FUNCTION"
        asmcode.writeFunction(vmcode.arg1, vmcode.arg2)
      end
      i = i+1
      puts i
      puts "vmcode.commandType #{vmcode.commandType}"
      puts "vmcode.arg1 #{vmcode.arg1}"
      puts "vmcode.arg2 #{vmcode.arg2}"
      vmcode.advance
    end
  end
end

asmcode.close
