require_relative 'StockModel'

#Abstract controller to so that we can use a console program
# or a web interface for the model, without worrying
class StockController
  #The index page lists all the selected stock symbols
  def index(stockSymbol, period)
    @symbols = {}
    @period = period.to_i
    threads = []

    #Spinning out the creation of each model instance to a new thread.
    stockSymbol.split(',').each do |symbol|
      threads << Thread.new do 
        @symbols[symbol] = StockModel.new(symbol, @period)
      end
    end

    threads.each do |thread|
      thread.join
    end
    return @symbols
  end

  #The show page shows the stock of the selected stock symbols
  # info for a single day.
  def show(date)
    data = {}
    @symbols.each do |key, value|
      data[key] = value.data[date]
      data[key][:sma]= value.sma(date, @period)
      data[key][:ema] = value.ema(date, @period)
    end
    return data
  end
end