#VMコードから機械語への変換とファイルへの書き込み
class CodeWriter

  attr_accessor :argument, :local, :static, :this, :that, :pointer, :temp

  #書き込みファイルを開く　スタックマシンを準備
  def initialize(filename)
    @writeFile = File.open("#{filename}", mode = "w")
    @argument = []
    @local = []
    @static = []
    @this = []
    @that = []
    @pointer = []
    @temp = []
    @callcounter = 0
    @returncounter = 0
    @function_name = ""
  end

  def writeInit
    @writeFile.puts "@256"
    @writeFile.puts "D=A"
    @writeFile.puts "@SP"
    @writeFile.puts "M=D"
    self.writeCall("Sys.init", 0)
  end

  #ラベルコマンドを書き出し
  def writeLabel(label)
    @writeFile.puts "(#{label})"
  end

  #labelへ移動コマンドを書き出し
  def writeGoto(label)
    @writeFile.puts "@#{label}"
    @writeFile.puts "0;JMP"
  end

  #スタックの最上位をPOP 0以外の場合labelへ移動, 0の場合次のコマンドへ移動コマンドを書き出し
  def writeIf(label)
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@#{label}"
    @writeFile.puts "D;JNE"
  end

  def writeCall(functionName, numArgs)
    @writeFile.puts "//writeCall #{functionName}"
    #returnアドレス格納 関数再呼び出し時も配列のリターンアドレスに格納される(同じ関数の再呼び出し用にthisにリターンアドレス)
    @callcounter = @callcounter + 1
    @writeFile.puts "@#{functionName}return-address#{@callcounter}"
    @writeFile.puts "D=A"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #呼び出し元のLCLベースアドレス格納
    @writeFile.puts "@LCL"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #呼び出し元のARGベースアドレス格納
    @writeFile.puts "@ARG"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #呼び出し元のTHISベースアドレス格納
    @writeFile.puts "@THIS"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #呼び出し元のTHATベースアドレス格納
    @writeFile.puts "@THAT"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #呼び出されたARGベースアドレス格納
    @writeFile.puts "@#{5 + numArgs}"
    @writeFile.puts "D=A"
    @writeFile.puts "@SP"
    @writeFile.puts "D=M-D"
    @writeFile.puts "@ARG"
    @writeFile.puts "M=D"
    #呼び出されたLCLベースアドレス格納
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@LCL"
    @writeFile.puts "M=D"
    #関数へジャンプ
    @writeFile.puts "@#{functionName}"
    @writeFile.puts "0;JMP"
    #returnラベル
    @writeFile.puts "(#{functionName}return-address#{@callcounter})"
  end

  #戻り値を保存できるよう変更
  def writeReturn
    @writeFile.puts "//writeReturn"
    @returncounter = @returncounter + 1
    @writeFile.puts "//writeReturn 戻り値保存"
    #戻り値保存
    #戻り値が複数ある場合
    #戻り値格納メモリ
    @writeFile.puts "@R13"
    @writeFile.puts "M=0"
    #リターンアドレス格納メモリ
    @writeFile.puts "@R14"
    @writeFile.puts "M=0"
    #一時格納場所
    @writeFile.puts "@R15"
    @writeFile.puts "M=0"
    #SPとTHAT(戻り値のベースアドレス)から戻り値を他の領域に格納
    #SPとTHAT(戻り値のベースアドレス)の差から戻り値の数を確認
    #↑不要　戻り値が複数ある場合も想定しなければならないときに必要　考慮しなくてよいため不要
    @writeFile.puts "@THAT"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "D=M-D"
    @writeFile.puts "@R13"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "AM=M-1"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@R13"
    @writeFile.puts "M=D"
    #初期化
    @writeFile.puts "@R14"
    @writeFile.puts "M=0"
    @writeFile.puts "@R15"
    @writeFile.puts "M=0"
    #ローカル変数削除
    @writeFile.puts "//writeReturn ローカル変数削除"
    #現在のSPとLCLの差からローカル変数の個数を計算
    #SP内に代入
    @writeFile.puts "@LCL"
    @writeFile.puts "D=M"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-D"
    @writeFile.puts "@LCL"
    @writeFile.puts "D=M"
    @writeFile.puts "@LOCALJUMP#{@returncounter}"
    @writeFile.puts "D;JEQ"
    #ローカル変数の削除
    @writeFile.puts "(LOCALDELETELOOP#{@returncounter})"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "MD=M-1"
    @writeFile.puts "@LOCALDELETELOOPEND#{@returncounter}"
    @writeFile.puts "D;JLT"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M-1"
    @writeFile.puts "M=D"
    @writeFile.puts "@LOCALDELETELOOP#{@returncounter}"
    @writeFile.puts "0;JMP"
    @writeFile.puts "(LOCALDELETELOOPEND#{@returncounter})"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    @writeFile.puts "(LOCALJUMP#{@returncounter})"
    #THAT
    @writeFile.puts "//writeReturn THAT"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@THAT"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    #THIS
    @writeFile.puts "//writeReturn THIS"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@THIS"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    #ARG
    @writeFile.puts "//writeReturn ARG"
    @writeFile.puts "@ARG"
    @writeFile.puts "D=M"
    @writeFile.puts "@R15"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@ARG"
    @writeFile.puts "M=D"
    #LCL
    @writeFile.puts "//writeReturn LCL"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@LCL"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    #リターンアドレス格納
    @writeFile.puts "//writeReturn リターンアドレス格納"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@R14"
    @writeFile.puts "M=D"
    #引数削除　スタックポインタ移動
    #現在のSPとARGの差から引数の個数を計算
    @writeFile.puts "//writeReturn 引数削除"
    #ARGのベースアドレスを代入したR15をSPへ代入
    @writeFile.puts "@R15"
    @writeFile.puts "D=M"
    #現在のSPとARGの差を計算
    @writeFile.puts "@SP"
    @writeFile.puts "D=M-D"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    #例外を排除
    @writeFile.puts "@R15"
    @writeFile.puts "D=M"
    @writeFile.puts "@256"
    @writeFile.puts "D=D-A"
    @writeFile.puts "@STACKPOINTJUMPSKIP#{@returncounter}"
    @writeFile.puts "D;JLT"
    #削除ループ
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "@STACKPOINTSKIP#{@returncounter}"
    @writeFile.puts "D;JLE"
    @writeFile.puts "(STACKPOINTLOOP#{@returncounter})"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "MD=M-1"
    @writeFile.puts "@STACKPOINTLOOPEND#{@returncounter}"
    @writeFile.puts "D;JLE"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@SP"
    @writeFile.puts "AM=M-1"
    @writeFile.puts "M=D"
    @writeFile.puts "@STACKPOINTLOOP#{@returncounter}"
    @writeFile.puts "0;JMP"
    @writeFile.puts "(STACKPOINTLOOPEND#{@returncounter})"
    @writeFile.puts "(STACKPOINTJUMPSKIP#{@returncounter})"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M-1"
    @writeFile.puts "(STACKPOINTSKIP#{@returncounter})"
    @writeFile.puts "@R15"
    @writeFile.puts "M=0"
    #戻り値格納
    @writeFile.puts "//writeReturn 戻り値格納"
    #戻り値を格納する
    #R13の値をスタックマシンへ格納
    @writeFile.puts "@R13"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "@SP"
    @writeFile.puts "A=M"
    @writeFile.puts "M=D"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    #ジャンプ
    @writeFile.puts "//writeReturn ジャンプ"
    #アドレス格納
    @writeFile.puts "@R14"
    @writeFile.puts "D=M"
    @writeFile.puts "M=0"
    @writeFile.puts "A=D"
    @writeFile.puts "0;JMP"
  end

  def writeFunction(functionName, numLocals)
    #関数へジャンプが必要　引数の保存が必要　⇒　ジャンプする必要はない？ジャンプが必要なのはCALL?
    #まず引数を保存
    @function_name = functionName.match(/\w*/).to_s
    @writeFile.puts "//writeFunction #{functionName}"
    @writeFile.puts "(#{functionName})"
    @writeFile.puts "@#{numLocals}"
    @writeFile.puts "D=A"
    @writeFile.puts "@R15"
    @writeFile.puts "M=D"
    @writeFile.puts "@R14"
    @writeFile.puts "M=0"
    @writeFile.puts "(#{functionName}FUNCTIONJUMPLOOP)"
    @writeFile.puts "@R14"
    @writeFile.puts "D=M"
    @writeFile.puts "@R15"
    @writeFile.puts "D=M-D"
    @writeFile.puts "@#{functionName}FUNCTIONJUMPLOOPEND"
    @writeFile.puts "D;JLE"
    @writeFile.puts "@R14"
    @writeFile.puts "D=M"
    @writeFile.puts "@LCL"
    @writeFile.puts "A=M+D"
    @writeFile.puts "M=0"
    @writeFile.puts "@R14"
    @writeFile.puts "M=M+1"
    @writeFile.puts "@SP"
    @writeFile.puts "M=M+1"
    @writeFile.puts "@#{functionName}FUNCTIONJUMPLOOP"
    @writeFile.puts "0;JMP"
    @writeFile.puts "(#{functionName}FUNCTIONJUMPLOOPEND)"
    @writeFile.puts "@R15"
    @writeFile.puts "M=0"
    @writeFile.puts "@R14"
    @writeFile.puts "M=0"
    #THATを戻り値の基準とする
    @writeFile.puts "@SP"
    @writeFile.puts "D=M"
    @writeFile.puts "@THAT"
    @writeFile.puts "M=D"
  end

  #読み込みファイル変更通知
  def setFileName(fileName)
    puts "現在#{fileName}を変換中です。"
    @writeFile.puts "// #{fileName}"
  end

  #VM算術演算をアセンブリに変換
  def writeArithmetic(command)
    case command
    when "add"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #次のスタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      #SP減算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #スタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=M+D"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "sub"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #次のスタックポインタ内にある値を取り出し+現在のスタックポインタの値との減算
      #SP減算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #スタックポインタ内にある値を取り出し+現在のスタックポインタの値との減算
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=M-D"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "neg"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=-M"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "eq"
      #比較対象a
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #比較対象b
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      #b-a
      @writeFile.puts "D=M-D"
      #b=a
      @writeFile.puts "@EQJUMP"
      @writeFile.puts "D;JEQ"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      @writeFile.puts "@EQNOTJUMP"
      @writeFile.puts "0;JMP"
      @writeFile.puts "(EQJUMP)"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=-1"
      @writeFile.puts "(EQNOTJUMP)"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "gt"#x>y
      #比較対象a=y
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #比較対象b=x
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      #b-a
      @writeFile.puts "D=M-D"
      #b>a
      @writeFile.puts "@GTJUMP"
      @writeFile.puts "D;JGT"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      @writeFile.puts "@GTNOTJUMP"
      @writeFile.puts "0;JMP"
      @writeFile.puts "(GTJUMP)"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=-1"
      @writeFile.puts "(GTNOTJUMP)"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "lt"
      #比較対象a
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #比較対象b
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      @writeFile.puts "A=M"
      #b-a
      @writeFile.puts "D=M-D"
      #b<a
      @writeFile.puts "@LTJUMP"
      @writeFile.puts "D;JLT"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      @writeFile.puts "@LTNOTJUMP"
      @writeFile.puts "0;JMP"
      @writeFile.puts "(LTJUMP)"
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=-1"
      @writeFile.puts "(LTNOTJUMP)"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "and"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #次のスタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      #SP減算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #スタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=M&D"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "or"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "D=M"
      #現在のスタックポインタ内にある値を0へ
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=0"
      #次のスタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      #SP減算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #スタックポインタ内にある値を取り出し+現在のスタックポインタの値との加算
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=M|D"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    when "not"
      #スタックポインタを値がある位置に動かす
      @writeFile.puts "@SP"
      @writeFile.puts "M=M-1"
      #現在のスタックポインタ内にある値を取り出し
      @writeFile.puts "@SP"
      @writeFile.puts "A=M"
      @writeFile.puts "M=!M"
      #SP加算
      @writeFile.puts "@SP"
      @writeFile.puts "M=M+1"
    else
      puts "writeArithmetic エラー"
    end
  end

  def writePushPop(command, segment, index)
    array = []
    if command == "C_PUSH"
      case segment
      when "argument"
        #変換処理
        #ARG内の値(ARGベースアドレス)+indexの値を格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@ARG"
        @writeFile.puts "A=D+M"#ARG内の値+index
        @writeFile.puts "D=M"#ARG内の値(ARGベースアドレス)+indexのデータを格納
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"#sp内のアドレスにある値を現在のアドレスにする
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "local"
        #変換処理
        #ARG内の値+indexをsp内のアドレスに格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@LCL"
        @writeFile.puts "A=D+M"#ARG内の値+index
        @writeFile.puts "D=M"#ARG内の値(ARGベースアドレス)+indexのデータを格納
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"#sp内のアドレスにある値を現在のアドレスにする
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "static"
        #変換処理
        #ファイルごとに専用のstatic
        @writeFile.puts "@#{@function_name}.#{index}"
        @writeFile.puts "D=M"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        @writeFile.puts "@#{@function_name}.#{index}"
        @writeFile.puts "M=D"
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "constant"
        #変換処理
        #スタック保存　右辺
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        #スタック保存　左辺
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "this"
        #変換処理
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@THIS"
        @writeFile.puts "A=D+M"#ARG内の値+index
        @writeFile.puts "D=M"#ARG内の値(ARGベースアドレス)+indexのデータを格納
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"#sp内のアドレスにある値を現在のアドレスにする
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "that"
        #変換処理
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@THAT"
        @writeFile.puts "A=D+M"#ARG内の値+index
        @writeFile.puts "D=M"#ARG内の値(ARGベースアドレス)+indexのデータを格納
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"#sp内のアドレスにある値を現在のアドレスにする
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "pointer"
        #変換処理
        if index == 0
          @writeFile.puts "@THIS"
        else
          @writeFile.puts "@THAT"
        end
        @writeFile.puts "D=M"
        #スタック保存　左辺
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        #スタック保存
        @writeFile.puts "M=D"
        #SP加算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M+1"
      when "temp"
        #スタックマシン処理
        if index < 8 && index >= 0
          #変換処理
          @writeFile.puts "@#{16 + index}"
          @writeFile.puts "D=M"
          @writeFile.puts "@SP"
          @writeFile.puts "A=M"
          @writeFile.puts "M=D"
          #SP加算
          @writeFile.puts "@SP"
          @writeFile.puts "M=M+1"
        else
          puts "tempセグメント範囲外です。"
        end
      end
    elsif command == "C_POP"
      case segment
      when "argument"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        #argumentに値を格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@ARG"
        @writeFile.puts "D=M+D"
        @writeFile.puts "@R15"
        @writeFile.puts "M=D"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        @writeFile.puts "@R15"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        #R15の値を消す
        @writeFile.puts "@R15"
        @writeFile.puts "M=0"
        #新たに格納した値を消す(0にする)
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=0"
      when "local"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        #LCL内の値+indexをsp内のアドレスに格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@LCL"
        @writeFile.puts "D=D+M"#LCL内の値+index
        @writeFile.puts "@R15"
        @writeFile.puts "M=D"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        @writeFile.puts "@R15"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        #R15の値を消す
        @writeFile.puts "@R15"
        @writeFile.puts "M=0"
        #新たに格納した値を消す(0にする)
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=0"
      when "static"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        #ファイルごとに専用のstatic
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        @writeFile.puts "@#{@function_name}.#{index}"
        @writeFile.puts "M=D"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=0"
      when "constant"
        puts "constant 処理なし"
      when "this"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        #メモリ内の値+indexをR15に格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@THIS"
        @writeFile.puts "D=M+D"
        @writeFile.puts "@R15"
        @writeFile.puts "M=D"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        @writeFile.puts "@R15"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        #R15の値を消す
        @writeFile.puts "@R15"
        @writeFile.puts "M=0"
        #新たに格納した値を消す(0にする)
        @writeFile.puts "@0"
        @writeFile.puts "D=A"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
      when "that"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        #メモリ内の値+indexをR15に格納
        @writeFile.puts "@#{index}"
        @writeFile.puts "D=A"
        @writeFile.puts "@THAT"
        @writeFile.puts "D=M+D"
        @writeFile.puts "@R15"
        @writeFile.puts "M=D"
        #スタックポインタ内の値をDへ
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        @writeFile.puts "@R15"
        @writeFile.puts "A=M"
        @writeFile.puts "M=D"
        #R15の値を消す
        @writeFile.puts "@R15"
        @writeFile.puts "M=0"
        #新たに格納した値を消す(0にする)
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=0"
      when "pointer"
        #変換処理
        #SP減算
        @writeFile.puts "@SP"
        @writeFile.puts "M=M-1"
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "D=M"
        if index == 0
          @writeFile.puts "@THIS"
        else
          @writeFile.puts "@THAT"
        end
        @writeFile.puts "M=D"
        #新たに格納した値を消す(0にする)
        @writeFile.puts "@SP"
        @writeFile.puts "A=M"
        @writeFile.puts "M=0"
      when "temp"
        #スタックマシン処理
        if index < 8 && index >= 0
          #変換処理
          #SP減算
          @writeFile.puts "@SP"
          @writeFile.puts "M=M-1"
          @writeFile.puts "@SP"
          @writeFile.puts "A=M"
          @writeFile.puts "D=M"
          @writeFile.puts "@R#{5 + index}"
          @writeFile.puts "M=D"
          #新たに格納した値を消す(0にする)
          @writeFile.puts "@SP"
          @writeFile.puts "A=M"
          @writeFile.puts "M=0"
        else
          puts "tempセグメント範囲外です。"
        end
      end
    else
      #8章で他のコマンドwriteは実装
    end
  end

  def close
    @writeFile.close
  end
end
