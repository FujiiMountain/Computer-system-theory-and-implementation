class SymbolTable
  #シンボルテーブルを作成
  #メモリ毎にシンボルテーブルを作成
  attr_reader :tableS, :tableF, :subtableA, :subtableV
  def initialize
    @tableS = {}
    @tableF = {}
    @subtableA = {}
    @subtableV = {}
    @counterS = 0
    @counterF = 0
    @counterA = 0
    @counterV = 0
  end

  def startSubroutine
    @subtableA = {}
    @subtableV = {}
    @counterA = 0
    @counterV = 0
  end

  def define(name, type, kind)
    case kind
    when "STATIC"
      #重複確認
      #重複の場合上書き
      flug = 0
      @tableS.each do |k, v|
        if k == name
          @tableS[name] = { type: type, index: @counterS }
          flug = 1
          break
        end
      end
      #新規登録
      if flug == 0
        @tableS[name] = { type: type, index: @counterS }
        @counterS = @counterS + 1
      end
    when "FIELD"
      #重複確認
      #重複の場合上書き
      flug = 0
      @tableF.each do |k, v|
        if k == name
          @tableF[name] = { type: type, index: @counterF }
          flug = 1
          break
        end
      end
      #新規登録
      if flug == 0
        @tableF[name] = { type: type, index: @counterF }
        @counterF = @counterF + 1
      end
    when "ARG"
      #重複確認
      #重複の場合上書き
      flug = 0
      @subtableA.each do |k, v|
        if k == name
          @subtableA[name] = { type: type, index: @counterA }
          flug = 1
          break
        end
      end
      #新規登録
      if flug == 0
        @subtableA[name] = { type: type, index: @counterA }
        @counterA = @counterA + 1
      end
    when "VAR"
      #重複確認
      #重複の場合上書き
      flug = 0
      @subtableV.each do |k, v|
        if k == name
          @subtableV[name] = { type: type, index: @counterV }
          flug = 1
          break
        end
      end
      #新規登録
      if flug == 0
        @subtableV[name] = { type: type, index: @counterV }
        @counterV = @counterV + 1
      end
    end
  end

  def varCount(kind)
    case kind
    when "ARG"
      return @counterA
    when "VAR"
      return @counterV
    when "STATIC"
      return @counterS
    when "FIELD"
      return @counterF
    end
  end

  #現在スコープを現在定義中のものと仮定　異なる場合要変更
  #　⇒　スコープを廃止　ARGから順番にした　条件が必要な場合要変更
  def kindOf(name)
    #ARG
    @subtableA.each do |key, value|
      if key == name
        return "ARG"
      end
    end
    #VAR
    @subtableV.each do |key, value|
      if key == name
        return "VAR"
      end
    end
    #STATIC
    @tableS.each do |key, value|
      if key == name
        return "STATIC"
      end
    end
    #FIELD
    @tableF.each do |key, value|
      if key == name
        return "FIELD"
      end
    end
    #該当なし
    return "NONE"
  end

  def typeOf(name)
    #ARG
    @subtableA.each do |key, value|
      if key == name
        return @subtableA[name][:type]
      end
    end
    #VAR
    @subtableV.each do |key, value|
      if key == name
        return @subtableV[name][:type]
      end
    end
    #STATIC
    @tableS.each do |key, value|
      if key == name
        return @tableS[name][:type]
      end
    end
    #FIELD
    @tableF.each do |key, value|
      if key == name
        return @tableF[name][:type]
      end
    end
  end

  def indexOf(name)
    #ARG
    @subtableA.each do |key, value|
      if key == name
        return @subtableA[name][:index]
      end
    end
    #VAR
    @subtableV.each do |key, value|
      if key == name
        return @subtableV[name][:index]
      end
    end
    #STATIC
    @tableS.each do |key, value|
      if key == name
        return @tableS[name][:index]
      end
    end
    #FIELD
    @tableF.each do |key, value|
      if key == name
        return @tableF[name][:index]
      end
    end
  end
end
