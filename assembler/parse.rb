require './symboltable.rb'

class Parse

  attr_reader :readlines, :lastcount, :counter, :command, :commandtypeA, :symbolA, :comp, :dest, :jump, :symbolTable, :error
  attr_writer :counter, :address, :lcounter

  def initialize(filenameplace)
    #ファイルを読み込み
    file = File.open(filenameplace,'r')
    @readlines = file.readlines
    #不要情報を削除
    @readlines.each do |rl|
      rl.gsub!(/\s+|\n+|\/{2}[[..]*[^\.]*]*/, '')#空白文字、改行、コメント条件を満たすものを削除
    end
    @readlines.delete("")#値がないものを削除
    @symbolTable = SymbolTable.new
    @lastcount = @readlines.count
    @counter = 0
    @commandtypeA = []
    @symbolA = []
    @comp = []
    @dest = []
    @jump = []
    @address = 16
    @lcounter = 0
    @error = 0
    file.close
  end

  def hasMoreCommands
    if @lastcount - @counter > 0
      true
    else
      false
    end
  end

  def advance
    if hasMoreCommands == true
      @counter = @counter + 1
    else
      @counter
    end
  end

  def commandType
    if @readlines[@counter].match(/^@+\w*/)
      @commandtypeA[@counter] = "A_COMMAND"
    elsif @readlines[@counter].match(/^\({1}[\w*\.*\$*\:*]*\){1}/)
      @commandtypeA[@counter] = "L_COMMAND"
    else
      @commandtypeA[@counter] = "C_COMMAND"
    end
  end

  def symbol
    if commandType == "A_COMMAND"
      @symbolA[@counter] = @readlines[@counter].delete("@")
      case @symbolA[@counter].length
      when 1
        judge = @symbolA[@counter].match(/^\d+/)
      when 2
        judge = @symbolA[@counter].match(/(^\d+[^a-zA-Z_]+)|(^\d+\S+)/)
      else
        judge = @symbolA[@counter].match(/^\d+[^a-zA-Z_]+\S+/)
      end
      if judge
        @symbolA[@counter] = @symbolA[@counter].to_i
      elsif @symbolA[@counter].match(/^[^\d]\w*\S*\.*\$*\:*/)
        case @symbolA[@counter]
        when "SP", "R0"
          @symbolA[@counter] = 0
        when "LCL", "R1"
          @symbolA[@counter] = 1
        when "ARG", "R2"
          @symbolA[@counter] = 2
        when "THIS", "R3"
          @symbolA[@counter] = 3
        when "THAT", "R4"
          @symbolA[@counter] = 4
        when "R5"
          @symbolA[@counter] = 5
        when "R6"
          @symbolA[@counter] = 6
        when "R7"
          @symbolA[@counter] = 7
        when "R8"
          @symbolA[@counter] = 8
        when "R9"
          @symbolA[@counter] = 9
        when "R10"
          @symbolA[@counter] = 10
        when "R11"
          @symbolA[@counter] = 11
        when "R12"
          @symbolA[@counter] = 12
        when "R13"
          @symbolA[@counter] = 13
        when "R14"
          @symbolA[@counter] = 14
        when "R15"
          @symbolA[@counter] = 15
        when "SCREEN"
          @symbolA[@counter] = 16384
        when "KBD"
          @symbolA[@counter] = 24576
        else
          @symbolA[@counter] = @symbolA[@counter].to_sym
          if @symbolTable.contains(@symbolA[@counter]) == false
            @symbolTable.addEntry(@symbolA[@counter], @address)
            @address = @address + 1
          end
          true
        end
      else
        puts "#{@symbolA[@counter]}のとき def symbol if commandType == A_COMMAND で条件を満たすものがありませんでした"
        @error = @error + 1
      end
    elsif commandType == "L_COMMAND"
      @symbolA[@counter] = @readlines[@counter].delete("(").delete(")").to_sym
        @symbolTable.addEntry(@symbolA[@counter], @counter - @lcounter)
      @lcounter = @lcounter + 1
    end
  end

  def splitC
    if commandType == "C_COMMAND"
      if @readlines[@counter].match(";")
        matchSC = @readlines[@counter].match(";")
        @comp[@counter] = matchSC.pre_match
        @dest[@counter] = "null"
        @jump[@counter] = matchSC.post_match
      elsif @readlines[@counter].match("=")
        matchEQ = @readlines[@counter].match("=")
        @comp[@counter] = matchEQ.post_match
        @dest[@counter] = matchEQ.pre_match
        @jump[@counter] = "null"
      else
        puts "一致がありませんでした"
      end
    end
  end
end
