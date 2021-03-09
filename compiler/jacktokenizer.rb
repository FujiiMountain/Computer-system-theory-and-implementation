class Tokenizer
  attr_reader :dataS, :dataA, :counter
  #今回は字句解析のため行毎ではなく単語毎にしなくてはならない　⇒　難しい？
  def initialize(name)
    @counter = 0
    bp = 0
    @dataA = []
    @data = File.open(name, 'r')
    @dataS = @data.read.to_s
    #コメントアウトの除去、APIドキュメント用のコメント除去？格納？
    i = 0
    size = @dataS.length
    #puts "dataS #{dataS}"
    while @dataS.match(/\/{2}(.)*?\n|\/\*[^\*]((.)*?(\s)*?)*?\*\/|\/\*\*((.)*?(\s)*?)*?\*\//) do
      #コメントが後ろにある行の文字列が変になる　改行、空欄除去される
      @dataA[i] = @dataS.slice!(/\/{2}(.)*?\n|\/\*[^\*]((.)*?(\s)*?)*?\*\/|\/\*\*((.)*?(\s)*?)*?\*\//)
      i = i + 1
      bp = bp + 1
      if bp > size
        puts "Tokenizer initialize comment : breakされました"
        break
      end
    end
    #ファイル内のデータから単語毎に配列内へ入れていく
    i = 0
    size = @dataS.length + 1
    while @dataS.match(/[a-zA-Z0-9_]+|\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~|\"((.)*?(b)*?)*?\"/) do
      @dataA[i] = @dataS.slice!(/[a-zA-Z0-9_]+|\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~|\"((.)*?(b)*?)*?\"/)
      @dataS.slice!(/\s{2,}/)
      i = i + 1
      bp = bp + 1
      if bp > size || @dataA[i - 1] == nil
        @dataA.pop
        break
      end
    end
    @data.close
  end

  def hasMoreTokens
    if @dataA[@counter + 1]
      return true
    else
      return false
    end
  end

  def advance
    if hasMoreTokens
      @counter = @counter + 1
    end
  end

  def tokenType
    case @dataA[@counter]
    when "class", "constructor", "function", "method", "field", "static", "var", "int", "char", "boolean", "void", "true", "false", "null", "this", "while", "return"
      return "KEYWORD"
    when "{", "}", "(", ")", "[", "]", ".", ",", ";", "+", "-", "*", "/", "&", "|", "<", ">", "=", "~"
      return "SYMBOL"
    else
      int = @dataA[@counter].slice(/\d+/)
      char = @dataA[@counter].slice(/\"((.)*[^\"]*[^\n]*)*\"/)
      identify = @dataA[@counter].slice(/[^\d]\w+/)
      if @dataA[@counter] == int
        return "INT_CONST"
      elsif @dataA[@counter] == char
        return "STRING_CONST"
      elsif @dataA[@counter] == identify
        return "IDENTIFIER"
      else
        puts "該当なし"
      end
    end
  end

  def keyWord
    if self.tokentype == "KEYWORD"
      return @dataA[@counter].upcase
    else
      puts "keyWord:呼び出し不可"
    end
  end

  def symbol
    if self.tokentype == "SYMBOL"
      return @dataA[@counter]
    end
  end

  def identifier
    if self.tokentype == "IDENTIFIER"
      return @dataA[@counter]
    end
  end

  def intVal
    if self.tokentype == "INT_CONST"
      return @dataA[@counter]
    end
  end

  def stringVal
    if self.tokentype == "STRING_CONST"
      return @dataA[@counter]
    end
  end
end
