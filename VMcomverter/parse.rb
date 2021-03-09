#VMコードの抽出と解析
class Parse

  attr_reader :data, :counter, :commandHead

  def initialize(filename)
    @file = File.new(filename)#ファイルデータ読み込み
    @data = @file.readlines#ファイルデータの各行を配列の各要素へ格納
    i = 0
    data = []
    puts "@data #{@data}"
    @data.each do |d|
      d.gsub!(/\r\n|\s*\/{2}(.*\s*)*/, "")#.gsub!(/\b{2,}/, " ")#コメントすべて、改行文字削除
      puts "d #{d}"
    end
    @data.delete('')#空行削除
    puts "@data.delete #{@data}"
    @counter = 0#現在の解析位置　ファイルデータの何行目かを示している
    @arg1 = []
    @arg2 = []
  end

  #次の行にデータが入っているかを確認
  def hasMoreCommands
    if @data[@counter + 1]
      true
    else
      false
    end
  end

  #次の行にデータが入っていれば解析位置を次にすすめる
  def advance
    if hasMoreCommands
      @counter = @counter + 1
    else
      @counter
    end
  end

  #データの形式からどういった種類の命令を記述しているのかを解析
  def commandType
    @commandHead = @data[@counter].match(/[\w*|\.*|\$*|\-*]+\s{0,1}/).to_s.sub(" ", "")#文字列の後の空白文字までを抽出(matchまで)、バックスペースを削除
    case @commandHead
    when "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not"
      "C_ARITHMETIC"
    when "push"
      "C_PUSH"
    when "pop"
      "C_POP"
    when "label"
      "C_LABEL"
    when "goto"
      "C_GOTO"
    when "if-goto"
      "C_IF"
    when "function"
      "C_FUNCTION"
    when "return"
      "C_RETURN"
    when "call"
      "C_CALL"
    else
      puts "commandType エラー"
    end
  end

  #第一引数を抽出
  def arg1
    if commandType == "C_ARITHMETIC"
      @commandHead
    elsif commandType == "C_RETURN"
      puts "arg1 エラー"
    else
      @target1 = @data[@counter].sub(@commandHead, "")#@dataから@commandを除去
      @arg1[@counter] = @target1.match(/[\w*|\.*|\$*|\-*]+[\s]*/).to_s.sub(' ', "")#残りから指定の文字列を抽出
    end
  end

  #第二引数を抽出
  def arg2
    if commandType == "C_PUSH" || commandType == "C_POP" || commandType == "C_FUNCTION" || commandType == "C_CALL"
      target2 = @target1.sub(@arg1[@counter], "")#@dataから@command,@arg1を除去
      @arg2[@counter] = target2.match(/[\w*|\.*|\$*|\-*]+[\s]*/).to_s.sub(' ', "").to_i#残りから指定の文字列を抽出
    else
      puts "arg2 エラー"
    end
  end
end
