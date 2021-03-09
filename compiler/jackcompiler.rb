#フォルダ名
#folderName = "Pong"
#必要なファイルを取り入れる
require "./jacktokenizer.rb"
require "./symboltable.rb"
require "./compilationengine.rb"
#入力ファイル
#fileName = "Ball"
#fileName = "Bat"
#fileName = "PongGame"
#fileName = "Main"
fileNames = []
i = 0
vmdirectoryname = "./#{folderName}"
Dir::foreach(vmdirectoryname) do |f|
  #拡張子がvmのものを探索　⇒　空白文字と拡張子を削除
  name = f.match(/[\w*|\.*|\$*|\-*]+(.jack){1}/).to_s.gsub(/\s/,"").to_s.gsub(/.jack/,"").to_s
  #シンボルテーブルのstaticテーブルへ格納
  if name != ""
    fileNames[i] = name
    i = i + 1
  end
end
#処理開始
fileNames.each do |fileName|
  inFilePlace = "./#{folderName}/#{fileName}.jack"
  #字句解析
  data = Tokenizer.new(inFilePlace)
  #出力ファイル
  outFilePlace = "./#{folderName}/#{fileName}.vm"
  writeFile = File.open(outFilePlace, "w")
  #変換準備
  changeData = Engine.new(data, writeFile)
  #OSの各クラス読み込み
  directorynames = []
  Dir::foreach(vmdirectoryname) do |f|
    #拡張子がvmのものを探索　⇒　空白文字と拡張子を削除
    name = f.match(/[\w*|\.*|\$*|\-*]+(.vm){1}/).to_s.gsub(/\s/,"").to_s.gsub(/.vm/,"").to_s
    #シンボルテーブルのstaticテーブルへ格納
    if name != ""
      changeData.table.define(name, name, "STATIC")
    end
    #OS登録
    name = "Array"
    changeData.table.define(name, name, "STATIC")
    name = "Keyboard"
    changeData.table.define(name, name, "STATIC")
    name = "Math"
    changeData.table.define(name, name, "STATIC")
    name = "Memory"
    changeData.table.define(name, name, "STATIC")
    name = "Output"
    changeData.table.define(name, name, "STATIC")
    name = "Screen"
    changeData.table.define(name, name, "STATIC")
    name = "String"
    changeData.table.define(name, name, "STATIC")
    name = "Sys"
    changeData.table.define(name, name, "STATIC")
  end
  #変換処理
  i = 0
  f = data.dataA.length - 1# 配列は0から開始のため実際の個数より-1
  while i < f do
    changeData.compileClass
    i = changeData.data.counter
  end
  puts "[#{fileName}]"
  puts "・Static\n#{changeData.table.tableS}"
  puts "[#{fileName}]"
  puts "・Feild\n#{changeData.table.tableF}"
  puts "[#{fileName}]"
  puts "・Argument\n#{changeData.table.subtableA}"
  puts "[#{fileName}]"
  puts "・Var\n#{changeData.table.subtableV}"
  puts ""
end
