require_relative 'StockModel'

class StockController
  def index(stockSymbol, period)
    @symbols = {}
    threads = []
    stockSymbol.split(',').each do |symbol|
      threads << Thread.new do 
        @symbols[symbol] = StockModel.new(symbol, 365, 5)
      end
    end

    threads.each do |thread|
      thread.join
    end
    return @symbols
  end
  def show(date)
    data = {}
    @symbols.each do |key, value|
      data[key] = value.data[date]
    end
    return data
  end
end