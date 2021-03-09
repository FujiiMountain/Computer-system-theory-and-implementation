#サンプルのアセンブラとこのアセンブラでテストファイルを変換して比較　変換結果がすべて同じであった
require './parse.rb'
require './code.rb'

#fileの名前と場所
filename = 'testfile'
filenameplace = "./#{filename}.asm"
binaryA = []
#init
text = Parse.new(filenameplace)

#１回目
text.readlines.each do
  puts text.commandType
  if text.commandType == "L_COMMAND"
    text.symbol
  end
  text.advance
end

text.counter = 0
text.lcounter = 0
text.address = 16

#２回目
text.readlines.each do
  if text.symbol
    if text.commandtypeA[text.counter] == "A_COMMAND"
      if text.symbolA[text.counter].class == Integer
        binaryA[text.counter] = "0" * (16 - text.symbolA[text.counter].to_s(2).length) + text.symbolA[text.counter].to_s(2)
      else
        binaryA[text.counter] = "0" * (16 - text.symbolTable.getAddress(text.symbolA[text.counter]).to_s(2).length) + text.symbolTable.getAddress(text.symbolA[text.counter]).to_s(2)
      end
    elsif text.commandtypeA[text.counter] == "L_COMMAND"
    end
  elsif text.splitC
    puts "@comp[@counter] #{text.comp[text.counter]}"
    binarycomp = Code.comp(text.comp[text.counter])
    binarydest = Code.dest(text.dest[text.counter])
    binaryjump = Code.jump(text.jump[text.counter])
    binaryA[text.counter] = "111" + binarycomp + binarydest + binaryjump
  end
  text.advance
end

binaryA.delete(nil)

if text.error == 0
  File.open("/home/fujii/デスクトップ/コンピュータシステムの理論と実装/asembler/#{filename}.hack", mode = "w") do |f|
    binaryA.each do |b|
      f.puts "#{b}\n"  # ファイルに書き込む
    end
  end
else
  puts "異常が発生しているため保存せずに終了しました"
end
