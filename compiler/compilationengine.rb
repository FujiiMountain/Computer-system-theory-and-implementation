require "./symboltable.rb"

class Engine

  attr_reader :dataA, :data
  attr_accessor :table

  def initialize(a, b)
    @data = a
    @dataA = a.dataA
    @writefile = b
    @class = ""
    @table = SymbolTable.new
    @parameterCounter = 0
    @staticCounter = 0
    @whileCounter = 0
    @whileStart = 1
    @whileLabelCounter = 0
    @whileStartCounter = 0
    @whileEndCounter = 0
    @ifCounter = 0
    @ifStart = 1
    @ifLabelCounter = 0
    @ifStartCounter = 0
    @ifEndCounter = 0
    @writefile.puts "call Sys.init 0"
  end

  def compileClass
    #クラス始まり
    @data.advance
    #クラス名前
    @class = @dataA[@data.counter]
    @data.advance
    #中括弧始まり
    @data.advance
    #クラス内変数、メソッドなど定義
    flug = 0
    while flug == 0 do
      case @dataA[@data.counter]
      when "static", "field"
        self.compileClassVarDec
      when "constructor", "function", "method"
        @table.startSubroutine
        self.compileSubroutine
      else
        flug = 1
      end
    end
    #中括弧終わり
    @data.advance
    #クラス終わり
    @class = ""
  end

  def compileClassVarDec
    #classvardec
    #static or field
    kind = @dataA[@data.counter].upcase
    @data.advance
    #type
    type = @dataA[@data.counter]
    @data.advance
    #varName
    name = @dataA[@data.counter]
    @data.advance
    #symboltableに情報追加
    @table.define(name, type, kind)
    #, varname*
    while @dataA[@data.counter] == "," do
      #,
      @data.advance
      #varname
      name = @dataA[@data.counter]
      @data.advance
      #symboltableに情報追加
      @table.define(name, type, kind)
    end
    #;
    @data.advance
    #classvardec 終わり
  end

  def compileSubroutine
    #subroutinedec 始まり
=begin
    #constructor or function or method
    case @dataA[@data.counter]
    #インスタンスの初期化
    when "constructor"
      @writefile.puts "<keyword> function </keyword>"
    when "function"
      @writefile.puts "<keyword> function </keyword>"
    when "method"
      @writefile.puts "<keyword> method </keyword>"
    end
=end
    #constructor function method
    select = 0
    case @dataA[@data.counter]
    when "constructor"
      select = 1
    when "method"
      select = 2
    when "function"
      select = 3
    end
    @data.advance
=begin
    #void or type
    case @dataA[@data.counter]
    when "void"
      @writefile.puts "<keyword> void </keyword>"
    #type
    when "int"
      @writefile.puts "<keyword> int </keyword>"
    when "char"
      @writefile.puts "<keyword> char </keyword>"
    when "boolean"
      @writefile.puts "<keyword> boolean </keyword>"
    else
      @writefile.puts "<identifier> #{@dataA[@data.counter]} </identifier>"
    end
=end
    @type = @dataA[@data.counter]
    @data.advance
    #subroutineName
    name = @dataA[@data.counter]
    @data.advance
    #メソッドのときのみベースアドレスをシンボルテーブルへ登録
    if select == 2
      @table.define(@class, @type, "ARG")
    end
    #(
    @data.advance
    #parameterList
    self.compileParameterList
    #)
    @data.advance
    #subroutineBody始まり
    # {
    @data.advance
    # varDec*
    flug = 0
    @varCounter = 0
    while flug == 0 do
      if @dataA[@data.counter] == "var"
        self.compileVarDec
      else
        flug = 1
      end
    end
    #VM言語へ変換 function
    case select
    when 1# constructor
      @writefile.puts "function #{@class}.#{name} #{@varCounter}"
      @writefile.puts "push constant #{@table.varCount("FIELD")}"
      @writefile.puts "call Memory.alloc 1"
      @writefile.puts "pop pointer 0"
      # statements
      self.compileStatements
      #↓メモリの確保量を記述 returnの前に置くためにthisのところに置く↓
      #@writefile.puts "push constant #{@letCounter}"
    when 2# method
      @writefile.puts "function #{@class}.#{name} #{@varCounter}"
      @writefile.puts "push argument 0"
      @writefile.puts "pop pointer 0"
      # statements
      self.compileStatements
    when 3# function
      @writefile.puts "function #{@class}.#{name} #{@varCounter}"
      # statements
      self.compileStatements
    end
    # }
    @data.advance
  end

  def compileParameterList
    #parameterList 始まり
    @parameterCounter = 0
    #呼び出されてもない場合があるため　⇒　ない場合の判定 ")"
    if @dataA[@data.counter] != ")"
      #type
      type = @dataA[@data.counter]
      @data.advance
      #varName
      name = @dataA[@data.counter]
      @data.advance
      #シンボルテーブル定義
      @table.define(name, type, "ARG")
      #@parameterCounter + 1
      @parameterCounter = @parameterCounter + 1
      #(, type varName)*
      while @dataA[@data.counter] == "," do
        #,
        @data.advance
        #type
        type = @dataA[@data.counter]
        @data.advance
        #varName
        name = @dataA[@data.counter]
        @data.advance
        #シンボルテーブル定義
        @table.define(name, type, "ARG")
        #@parameterCounter + 1
        @parameterCounter = @parameterCounter + 1
      end
    end
    #parameterList 終わり
  end

  def compileVarDec
    # vardec 始まり
    # var
    kind = @dataA[@data.counter].upcase
    @data.advance
    # type
    type = @dataA[@data.counter]
    @data.advance
    # varName
    name = @dataA[@data.counter]
    @data.advance
    #symboltableに情報追加
    @table.define(name, type, kind)
    @varCounter = @varCounter + 1
    # (, varName)*
    while @dataA[@data.counter] == "," do
      #,
      @data.advance
      #varName
      name = @dataA[@data.counter]
      @data.advance
      #symboltableに情報追加
      @table.define(name, type, kind)
      @varCounter = @varCounter + 1
    end
    #  ;
    @data.advance
    # vardec 終わり
  end

  def compileStatements
    #0回以上のため条件分岐　0回のときとそれ以外
    #statement*
    #0回のときとそれ以外の条件分岐
    if @dataA[@data.counter] != "}"
      #Statements
      #@dataA[@data.counter] == ( "let" | "if" | "while" | "do" | "return" )　に限り処理し続ける
      while @dataA[@data.counter] == "let" || @dataA[@data.counter] == "if" || @dataA[@data.counter] == "while" \
                                           || @dataA[@data.counter] == "do" || @dataA[@data.counter] == "return" do
        #letStatement or ifStatement or whileStatement or do or returnStatement
        case @dataA[@data.counter]
        when "let"
          self.compileLet
        when "if"
          self.compileIf
        when "while"
          self.compileWhile
        when "do"
          self.compileDo
        when "return"
          self.compileReturn
        end
      end
      # Statements
    end
  end

  def compileDo
    #doStatement
    #do
    @data.advance
    #subroutineCall
    #条件分岐
    if @dataA[@data.counter + 1] == "("
      # subroutineName
      callName = @dataA[@data.counter]
      @data.advance
      #pointer 0 をargument 0　へ　pointer 0　はオブジェクトのベースアドレスとしている　エラーになる可能性あり
      @writefile.puts "push pointer 0"
      # (
      @data.advance
      # expressionList
      self.compileExpressionList
      # )
      @data.advance
      #VM変換
      @writefile.puts "call #{@class}.#{callName} #{@argumentCount + 1}"
    elsif @dataA[@data.counter + 1] == "."
      # className or varName
      name = @dataA[@data.counter]
      @data.advance
      # .
      @data.advance
      # subroutineName
      subName = @dataA[@data.counter]
      @data.advance
      #インスタンス名からベースアドレスを見つける
      #①インスタンス名から格納されているシンボルテーブルの種類とインデックス番号を見つける
      #②対応するメモリセグメントへインデックス番号をいれる
      #constructor, function or methodかをnameで判別
      nameCorI = name.match(/^[A-Z]/)
      if nameCorI
        #constructor, function
        #constructor
        if subName == "new"
          # (
          @data.advance
          # expressionList
          self.compileExpressionList
          # )
          @data.advance
          #alloc 引数に確保メモリ量をpush
          #確保メモリ量はcallすれば結果が返される
          @writefile.puts "call #{name}.#{subName} #{@argumentCount}"
          @writefile.puts "call Memory.alloc 1"
        #function
        else
          # (
          @data.advance
          # expressionList
          self.compileExpressionList
          # )
          @data.advance
          #変換@argumentCount
          className = @table.typeOf(name)
          @writefile.puts "call #{className}.#{subName} #{@argumentCount}"
        end
      else
        #method
        #nameはインスタンス
        ###
        #インスタンス名からベースアドレスを見つける
        while 0 do
          if @table.subtableA[name]
            classType = @table.subtableA[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "ARG"
              @index = @table.subtableA[name][:index]
              break
            end
          end
          if @table.subtableV[name]
            classType = @table.subtableV[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "VAR"
              @index = @table.subtableV[name][:index]
              break
            end
          end
          if @table.tableS[name]
            classType = @table.tableS[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "STATIC"
              @index = @table.tableS[name][:index]
              break
            end
          end
          if @table.tableF[name]
            classType = @table.tableF[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "FIELD"
              @index = @table.tableF[name][:index]
              break
            end
          end
          @writefile.puts "エラー：見つかりませんでした"
          break
        end
        #メモリセグメントを選択
        case @memoryType
        when "ARG"
          @memoryTypeN = "argument"
        when "VAR"
          @memoryTypeN = "local"
        when "STATIC"
          @memoryTypeN = "static"
        when "FIELD"
          @memoryTypeN = "this"
        else
          @writefile.puts "エラー：該当なし"
        end
        ###
        className = @table.typeOf(name)
        #argument 0 にオブジェクトのベースアドレス
        @writefile.puts "push #{@memoryTypeN} #{@index}"
        # (
        @data.advance
        # expressionList
        self.compileExpressionList
        # )
        @data.advance
        #変換@argumentCount
        @writefile.puts "call #{className}.#{subName} #{@argumentCount + 1}"
      end
    else
      puts "compileDo: エラー"
    end
    #;
    @data.advance
    #doStatement
  end

  def compileLet
    #letStatement
    variableType = 0
    #let
    @data.advance
    #varName
    varName = @dataA[@data.counter]
    @data.advance
    #条件分岐
    if @dataA[@data.counter] == "["
      #[
      variableType = 1
      @data.advance
      #expression
      self.compileExpression
      #]
      @data.advance
    end
    #=
    @data.advance
    #配列の場合　シンボル：ベースアドレス　配列：値
    #@writefile.puts "push local #{@table.indexOf(varName)}" #←これ必要？
    case @table.kindOf(varName)
    when "ARG"
      memoryType = "argument"
    when "VAR"
      memoryType = "local"
    when "STATIC"
      memoryType = "static"
    when "FIELD"
      memoryType = "this"
    end
    if variableType == 1
      #[expression]でpushされているものと加算し、pointer 1へ
      @writefile.puts "push #{memoryType} #{@table.indexOf(varName)}"
      @writefile.puts "add"
      @writefile.puts "pop pointer 1"
    end
    #expression
    #変換 右辺
    self.compileExpression
    #;
    @data.advance
    #右辺でpushされたものを左辺へ代入
    if variableType == 0
      @writefile.puts "pop #{memoryType} #{@table.indexOf(varName)}"
    elsif variableType == 1
      @writefile.puts "pop that 0"
    end
    #letStatement
  end

  def compileWhile
    #whileStatement
    #@whileStartCounter = @whileStartCounter + 1
    #@whileLabelCounter = @whileLabelCounter + 1
    #whileEndCountinueCounter = 0
    #@whileCounter = @whileLabelCounter - whileEndCountinueCounter
    @whileCounter = @whileCounter + 1
    whileCounter = @whileCounter
    #ラベル
    @writefile.puts "label whileSTART#{whileCounter}"
    #while
    @data.advance
    #(
    @data.advance
    #expression
    self.compileExpression
    #)
    @data.advance
    #変換　JUMP
    @writefile.puts "if-goto while#{whileCounter}"
    @writefile.puts "goto whileEND#{whileCounter}"
    @writefile.puts "label while#{whileCounter}"
    #{
    @data.advance
    #statements
    self.compileStatements
    #}
    @data.advance
    #変換　JUMP
    @writefile.puts "goto whileSTART#{whileCounter}"
    @writefile.puts "label whileEND#{whileCounter}"
    #whileStatement
  end

  def compileReturn
    #returnStatement
    #return
    @data.advance
    #expression
    if @type == "void"
      @writefile.puts "push constant 0"
    elsif @dataA[@data.counter] != ";"
      self.compileExpression
    end
    #;
    @data.advance
    #変換 return
    @writefile.puts "return"
    #returnStatement
  end

  def compileIf
    #ifStatement
    #ifの中にifがある場合のラベル付に対応するため@ifStartCounter, @ifEndCounterを使用
    #ifの中にifがあるかの判定は@ifStartCounter, @ifEndCounterが等しいか
    #@ifStartCounter = @ifStartCounter + 1
    #@ifLabelCounter = @ifLabelCounter + 1
    #@ifEndCountinueCounter = 0
    #@elseFlug = 0
    #@ifCounter = @ifLabelCounter - @ifEndCountinueCounter
    @ifCounter = @ifCounter + 1
    ifCounter = @ifCounter
    #if
    @data.advance
    #(
    @data.advance
    #expression
    self.compileExpression
    #)
    @writefile.puts "if-goto IF#{ifCounter}"
    @writefile.puts "goto notIF#{ifCounter}"
    @data.advance
    @writefile.puts "label IF#{ifCounter}"
    #{
    @data.advance
    #statements
    self.compileStatements
    #}
    @data.advance
    @writefile.puts "goto IFEND#{ifCounter}"
    @writefile.puts "label notIF#{ifCounter}"
    #else条件分岐
    if @dataA[@data.counter] == "else"
      #else
      @data.advance
      #{
      @data.advance
      #statements
      self.compileStatements
      #}
      @data.advance
    end
    #ifStatement
    @writefile.puts "label IFEND#{ifCounter}"
  end

  def compileExpression
    #expression
    #term
    self.compileTerm
    #(op term)*
    flug = 0
    while flug == 0 do
      #puts "@dataA[@data.counter-1] #{@dataA[@data.counter-1]} @dataA[@data.counter] #{@dataA[@data.counter]} @data.counter #{@data.counter}"
      #op条件分岐
      #if @dataA[@data.counter] == ( "+" || "-" || "*" || "/" || "&" || "|" || "<" || ">" || "=" )
      #↑上の条件分岐は適切に判別してくれない
      if @dataA[@data.counter] == "+" || @dataA[@data.counter] == "-" || @dataA[@data.counter] == "*" || @dataA[@data.counter] == "/" \
                                 || @dataA[@data.counter] == "&" || @dataA[@data.counter] == "|" || @dataA[@data.counter] == "<" \
                                 || @dataA[@data.counter] == ">" || @dataA[@data.counter] == "="
        #op
        case @dataA[@data.counter]
        when "+"
          command = "add"
          @data.advance
        when "-"
          command = "sub"
          @data.advance
        when "*"
          command = "call Math.multiply 2"
          @data.advance
        when "/"
          command = "call Math.divide 2"
          @data.advance
        when "&"
          command = "and"
          @data.advance
        when "|"
          command = "or"
          @data.advance
        when "<"
          command = "lt"
          @data.advance
        when ">"
          command = "gt"
          @data.advance
        when "="
          command = "eq"
          @data.advance
        end
        #term
        self.compileTerm
        @writefile.puts "#{command}"
      else
        flug = 1
      end
    end
    #expression
  end

  def compileTerm
    #term
    #int or string or keyword or varName or varName[expression] or subroutineCall or (expression) or unaryOp term
    int = @dataA[@data.counter].slice(/\d+/)
    char = @dataA[@data.counter].slice(/\"((.)*?(\b)*?[^\"]*?[^\n]*?)*?\"/)#string
    identify = @dataA[@data.counter].slice(/^[^\d]\w+|[a-zA-Z_]/)
    case @dataA[@data.counter]
    #優先順位１
    #identifyより上にする
    when "true"
      @writefile.puts "push constant 1"
      @writefile.puts "neg"
      @data.advance
      return
    when "false"
      @writefile.puts "push constant 0"
      @data.advance
      return
    when "null"
      @writefile.puts "push constant 0"
      @data.advance
      return
    when "this"
      #オブジェクトのベースアドレスを返す
      @writefile.puts "push pointer 0"
      @data.advance
      return
    when "-"
      @data.advance
      self.compileTerm
      @writefile.puts "neg"
      return
    when "~"
      @data.advance
      self.compileTerm
      @writefile.puts "not"
      return
    when "("
      #(
      @data.advance
      #expression
      self.compileExpression
      #)
      @data.advance
      return
    end
    #subroutineCall
    #条件分岐
    case @dataA[@data.counter + 1]
    #methodのみ
    when "("
      # subroutineName
      subName = @dataA[@data.counter]
      @data.advance
      #pointer 0 がベースアドレスとする　エラーになる可能性あり
      @writefile.puts "push pointer 0"
      # (
      @data.advance
      # expressionList
      self.compileExpressionList
      # )
      @data.advance
      #変換
      #callの後でやりたい　⇒　アセンブリでメモリ操作時、call時現在の参照アドレスを保存した後ファンクションへジャンプした記憶があるため
=begin
      index = @table.varCount(@class)
      memoryType = @table.kindOf(@class).downcase
      case memoryType
      when "ARG"
        memoryTypeN = "argument"
      when "VAR"
        memoryTypeN = "local"
      when "STATIC"
        memoryTypeN = "static"
      when "FIELD"
        memoryTypeN = "this"
      else
        @writefile.puts "エラー：該当なし"
      end
      @writefile.puts "push #{memoryTypeN} #{index}"
=end
      @writefile.puts "call #{@class}.#{subName} #{@argumentCount + 1}"
      return
    #constructor, function, methodの場合あり
    when "."
      # className or varName
      name = @dataA[@data.counter]
      @data.advance
      # .
      @data.advance
      # subroutineName
      subName = @dataA[@data.counter]
      @data.advance
      #インスタンス名からベースアドレスを見つける
      #①インスタンス名から格納されているシンボルテーブルの種類とインデックス番号を見つける
      #②対応するメモリセグメントへインデックス番号をいれる
      #constructor, function or methodかをnameで判別
      nameCorI = name.match(/^[A-Z]/)
      if nameCorI
        #constructor, function
        #constructor
        if subName == "new"
          # (
          @data.advance
          # expressionList
          self.compileExpressionList
          # )
          @data.advance
          #alloc 引数に確保メモリ量をpush
          #確保メモリ量はcallすれば結果が返される　⇒　返されるのはベースアドレス
          @writefile.puts "call #{name}.#{subName} #{@argumentCount}"
          #@writefile.puts "call Memory.alloc 1"
          return
        #function
        else
          # (
          @data.advance
          # expressionList
          self.compileExpressionList
          # )
          @data.advance
          #変換@argumentCount
          className = @table.typeOf(name)
          @writefile.puts "call #{className}.#{subName} #{@argumentCount}"
          return
        end
      else
        #method
        #nameはインスタンス
        ###
        #インスタンス名からベースアドレスを見つける
        while 0 do
          if @table.subtableA[name]
            classType = @table.subtableA[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "ARG"
              @index = @table.subtableA[name][:index]
              break
            end
          end
          if @table.subtableV[name]
            classType = @table.subtableV[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "VAR"
              @index = @table.subtableV[name][:index]
              break
            end
          end
          if @table.tableS[name]
            classType = @table.tableS[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "STATIC"
              @index = @table.tableS[name][:index]
              break
            end
          end
          if @table.tableF[name]
            classType = @table.tableF[name][:type]
            if classType != "int" && classType != "boolean" && classType != "char"
              @memoryType = "FIELD"
              @index = @table.tableF[name][:index]
              break
            end
          end
          @writefile.puts "エラー：見つかりませんでした"
          break
        end
        #メモリセグメントを選択
        case @memoryType
        when "ARG"
          @memoryTypeN = "argument"
        when "VAR"
          @memoryTypeN = "local"
        when "STATIC"
          @memoryTypeN = "static"
        when "FIELD"
          @memoryTypeN = "this"
        else
          @writefile.puts "エラー：該当なし"
        end
        ###
        className = @table.typeOf(name)
        #argument 0 にオブジェクトベースアドレス
        @writefile.puts "push #{@memoryTypeN} #{@index}"
        # (
        @data.advance
        # expressionList
        self.compileExpressionList
        # )
        @data.advance
        #変換@argumentCount
        @writefile.puts "call #{className}.#{subName} #{@argumentCount + 1}"
        return
      end
    end
    #優先順位２
    case @dataA[@data.counter]
    when int#integer
      @writefile.puts "push constant #{@dataA[@data.counter]}"
      @data.advance
      return
    when char#string
      data = @dataA[@data.counter].delete("\"")
      @writefile.puts "// #{data}"
      @writefile.puts "push constant #{data.length}"
      #this 0:文字列の長さ, this 1:文字列のpointer, this 2:数値の0, 戻り値にStringのベースアドレス
      @writefile.puts "call String.new 1"
      #utf8にエンコード、数値へ変換
      dataE = data.encode("ASCII")
      arr = dataE.chars
      arr = arr.map do |str|
        str.ord
      end
      #数値へ変換したものを確保したそれぞれのデータへ格納
      i = 0
      while i < data.length
        @writefile.puts "push constant #{arr[i]}"
        @writefile.puts "call String.appendChar 2"
        #↓不要　String.appendCharでやってくれる↓
        #@writefile.puts "push constant 1"
        #@writefile.puts "add"
        i = i + 1
      end
      @data.advance
      return
    when identify#varName or varName[expression]
      variableType = 0
      identifySymbol = @dataA[@data.counter]
      identifyType = @table.kindOf(identifySymbol)
      identifyIndex = @table.indexOf(identifySymbol)
      case identifyType
      when "ARG"
        memoryType = "argument"
      when "VAR"
        memoryType = "local"
      when "STATIC"
        memoryType = "static"
      when "FIELD"
        memoryType = "this"
      end
      @data.advance
      #varName[expression]条件分岐
      if @dataA[@data.counter] == "["
        variableType = 1
        #[
        @data.advance
        #expression
        self.compileExpression
        #]
        @data.advance
        #変換
        #[expression]でpushされているものと加算し、pointer 1へ
        @writefile.puts "push #{memoryType} #{identifyIndex}"
        @writefile.puts "add"
        @writefile.puts "pop pointer 1"
      end
      #変換
      if variableType == 0
        @writefile.puts "push #{memoryType} #{identifyIndex}"
      elsif variableType == 1
        @writefile.puts "push that 0"
      end
      return
    end
    #term
  end

  def compileExpressionList
    @argumentCount = 0
    #ExpressionList
    int = @dataA[@data.counter].slice(/\d+/)
    char = @dataA[@data.counter].slice(/\"((.)*?(\b)*?[^\"]*?[^\n]*?)*?\"/)#string
    identify = @dataA[@data.counter].slice(/^[^\d]\w+|[a-zA-Z_]/)
    if @dataA[@data.counter] == int || @dataA[@data.counter] == char || @dataA[@data.counter] == identify || @dataA[@data.counter] == "true" \
                               || @dataA[@data.counter] == "false" || @dataA[@data.counter] == "null" || @dataA[@data.counter] == "this"\
                               || @dataA[@data.counter] == "-" || @dataA[@data.counter] == "~" || @dataA[@data.counter] == "(" \
                               || @dataA[@data.counter + 1] == "(" || @dataA[@data.counter + 1] == "."
      #expression
      self.compileExpression
      @argumentCount = @argumentCount + 1
      #(, expression)*条件分岐
      if @dataA[@data.counter] == ","
        #(, expression)*
        flug = 0
        while flug == 0 do
          #,
          @data.advance
          #expression
          self.compileExpression
          @argumentCount = @argumentCount + 1
          #終了条件
          if @dataA[@data.counter] != ","
            flug = 1
          end
        end
      end
    end
    #ExpressionList
  end
end
