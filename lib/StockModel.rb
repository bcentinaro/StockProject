require 'net/http'
require 'csv'
require 'json' # For JSON rendering
require 'active_support' # For Cache


class StockModel
  attr_reader :startDate, :endDate, :symbol, :csv, :data, :csvData

  def initialize(symbol, daysHistory, period, options = {})
    #initialize cache if it's not already
    unless defined?(@@cache)
      # Just a simple in memory cache store 
      @@cache = ActiveSupport::Cache::MemoryStore.new
    end
    # Setup the instance variables
    @endDate = Date.today
    @startDate = Date.today - (daysHistory + period)
    @symbol = symbol.strip
    @csvData = ''
    @smaMemo = {}
    @emaMemo = {}


    if @@cache.exist?("#{symbol.strip}-#{daysHistory}-#{period}")
      model = @@cache.fetch("#{symbol.strip}-#{daysHistory}-#{period}")
      if model[:endDate] == Date.today
        @smaMemo = model[:smaMemo]
        @emaMemo = model[:emaMemo]
        @csv = model[:csv]
        @data = model[:data]
        return self
      end
    end


    
    #Pull down the stock history from yahoo.
    Net::HTTP.start("ichart.finance.yahoo.com") do |http|
      resp = http.get("/table.csv?s=#{@symbol}" +
      "&a=#{@startDate.month}&b=#{@startDate.day}&c=#{@startDate.year}" +
      "&d=#{@endDate.month}&e=#{@endDate.day}&f=#{@endDate.year}&g=d&ignore=.csv")
      @csvData = resp.body
    end

    # Go though the stock history
    
    @data = {}
    @csv = CSV.parse(@csvData)
    @csv.drop(1) # We don't need the header
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
        @data[row[0]][:sma] = sma(row[0], period)
        @data[row[0]][:ema] = ema(row[0], period)
      end
      
      index = index - 1
    end

    @@cache.write("#{symbol}-#{daysHistory}-#{period}", to_hash)
  end

  #Simple Moving Average
  def sma(date, period)
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
    #Checking Memo Data
    unless @emaMemo["#{date}-#{period}"].nil?
      return @emaMemo["#{date}-#{period}"]
    end
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
    multiplier = (2 / (period + 1) )

    #return the EMA based on provided calculation.
    emaValue = ((@data[date][:close] - previousEma) * multiplier + previousEma).round(2)
    @emaMemo["#{date}-#{period}"] = emaValue
    return emaValue

  end

  #Persistance Functions
  def save(path, format)
    file = ''
    case format.downcase
      when 'csv'
        file = @csvData
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
      :smaMemo=>@smaMemo,
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