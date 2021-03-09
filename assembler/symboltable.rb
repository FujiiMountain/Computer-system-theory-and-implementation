class SymbolTable

  attr_reader :table

  def initialize
    @table = {}
  end

  def addEntry(symbol, address)
    @table[symbol] = address
  end

  def contains(symbol)
    @table.keys.each do |tk|
      if symbol == tk
        return true
      end
    end
    return false
  end

  def getAddress(symbol)
    @table[symbol]
  end
end
