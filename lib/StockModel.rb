require 'net/http'
require 'csv'
require 'json' # For JSON rendering
require 'active_support' # For Cache


class StockModel
  attr_reader :startDate, :endDate, :symbol, :csv, :data, :csvData

  def initialize(symbol,  period, options = {})
    #initialize cache if it's not already
    unless defined?(@@cache)
      # Just a simple in memory cache store 
      @@cache = ActiveSupport::Cache::MemoryStore.new
    end
    # Setup the instance variables
    @endDate = Date.today
    @startDate =  Date.parse('1900-01-01')
    @symbol = symbol.strip
    @csvData = ''
    @emaMemo = {}
    @csv = []

    #Check the cache for csv / data  and emaMemo
    if @@cache.exist?("#{symbol.strip}-#{period}")
      model = @@cache.fetch("#{symbol.strip}-#{period}")
      if model[:endDate] == Date.today
        @emaMemo = model[:emaMemo]
        @csv = model[:csv]
        @data = model[:data]
      end
    end

    #check to see if we pulled data from cache
    if @csv.empty?
      #Pull down the stock history from yahoo.
      Net::HTTP.start("ichart.finance.yahoo.com") do |http|
        resp = http.get("/table.csv?s=#{@symbol}" +
        "&a=#{@startDate.month}&b=#{@startDate.day}&c=#{@startDate.year}" +
        "&d=#{@endDate.month}&e=#{@endDate.day}&f=#{@endDate.year}&g=d&ignore=.csv")
        @csvData = resp.body
      end

      @csv = CSV.parse(@csvData)
      @csv.drop(1) # We don't need the header
    end
    # Go though the stock history
  
    @data = {}
    
    index = @csv.length() -1 
    csvReverse = @csv.reverse #we need to load oldest data first.
    csvReverse.each do |row|
      unless row[0] == 'Date'
      
        @data[row[0]] = {
          :open=>row[1].to_f,
          :high=>row[2].to_f,
          :low=>row[3].to_f,
          :close=>row[4].to_f,
          :volume=>row[5].to_f,
          :adjClose=>row[6].to_f,
          :index=>index, 
        }
        #Need to make sure to hit the EMA in advance
        # other wise EMA recurssion can throw StackToDeep errors
        ema(row[0], period)
      end
    
      index = index - 1
    end



    @@cache.write("#{symbol}-#{period}", to_hash)
  end

  #Simple Moving Average
  def sma(date, period)
    period = period.to_i #need to make sure this is an int

    # Get the index value of the date provided
    index = @data[date][:index]
    
    # if we don't have enough data to provide the avarage
    # return nil
    if  (index + period) > @data.length
      return nil
    end
    
    # Take the average closing cost of the couse of the provided period
    sum = 0.0 #@data[date][:close].to_f
    (period).times do |x|
      newDate = @csv[index + x][0]
      sum = sum + @data[newDate][:close].to_f
    end

    return (sum / period.to_f).round(2)
  end

  #Exponential Moving Average
  def ema(date, period)
    #Checking Memo Data - can save us a ton of processing time
    # on recursion, so long as we do it in the right order.
    unless @emaMemo["#{date}-#{period}"].nil?
      return @emaMemo["#{date}-#{period}"]
    end
    period = period.to_i #need to make sure this is an int

    #Getting the index value of the date provided
    index = @data[date][:index]

    #if we don't have enough data to provide the average return nil
    if  (index + period) > @data.length
      return nil
    end

    #Get the previous day's index value, and EMA.
    #if we don't have an EMA value, use SMA. (this should only happen once)
    previousDate = @csv[index + 1][0]
    previousEma = ema(previousDate, period)
    if previousEma.nil?
      return sma(date, period)
    end
    
    #Calculate the multiplier, which is based on the period
    multiplier = (2.0 / (period + 1.0) )

    #return the EMA based on provided calculation.
    emaValue = ((@data[date][:close] - previousEma) * multiplier + previousEma)
    @emaMemo["#{date}-#{period}"] = emaValue
    return emaValue

  end

  #Functions added for graphing
  def recentEMA(period, days)
    emaData = []
    days.times do |x|
      unless csv[days-x].nil? 
        date = csv[days - x][0]
        emaData << ema(date, period)
      end
    end
    return emaData
  end

  #functions added for graphing
  def recentSMA(period, days)
    smaData = []
    days.times do |x|
      unless csv[days-x].nil? 
        date = csv[days - x][0]
        smaData << sma(date, period)
      end
    end
    return smaData
  end

  def recentClosing(days)
    closingData = []
    days.times do |x|
      unless csv[days-x].nil? 
        date = csv[days - x][0]
        closingData << data[date][:close]
      end
    end
    return closingData
  end

  #Persistance Functions
  def save(path, format)
    file = ''
    case format.downcase
      when 'json'
        file = to_json
    end
    File.open("#{path}.#{format}", 'w') {|f| f.write(file) }
  end


  # Serialization functions
  def to_hash()
    return {
      :startDate=>@startDate, 
      :endDate=>@endDate,
      :symbol=>@symbol,
      :csv=>@csv,
      :data=>@data,
      :emaMemo=>@emaMemo
    }
  end


  def to_json(options = {})
    return to_hash.to_json
  end

  def to_s
    return to_hash.to_s
  end
end