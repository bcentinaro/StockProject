require 'net/http'
require 'csv'
require 'json'


class StockModel
  attr_reader :startDate, :endDate, :symbol, :csv, :data
  def initialize(symbol, daysHistory, period)
    # Setup the dates
    @endDate = Date.today
    # we want to make sure we cover the period as well.
    @startDate = Date.today - (daysHistory + period)

    @symbol = symbol.strip
    @csvData = ''
    Net::HTTP.start("ichart.finance.yahoo.com") do |http|
      resp = http.get("/table.csv?s=#{@symbol}" +
      "&a=#{@startDate.month}&b=#{@startDate.day}&c=#{@startDate.year}" +
      "&d=#{@endDate.month}&e=#{@endDate.day}&f=#{@endDate.year}&g=d&ignore=.csv")
      
      #Ideally this should be cached for reuse, because stock history won't chance in a day
      #but for now we'll just do a http call each time.
      @csvData = resp.body
    end
    index = 0
    @data = {}
    @csv = []
    CSV.parse(@csvData) do |row|
      @csv << row
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
      end
      
      index = index + 1
    end
    @data.each do |key, value|
      value[:sma] = sma(key, period)
      value[:ema] = ema(key, period)
    end
  end


  def sma(date, period)
  
    index = @data[date][:index]
    if  (index + period) > @data.length
      return nil
    end
    sum = 0.0
    
    period.times do |x|
      newDate = @csv[index + x][0]
      sum = sum + @data[newDate][:close].to_f
    end
    return (sum / period.to_f).round(2)
  end

  def ema(date, period)
    index = @data[date][:index]
    if  (index + period) > @data.length
      return nil
    end
    previousDate = @csv[index + 1][0]
    previousEma = ema(previousDate, period)
    if previousEma.nil?
      return sma(date, period)
    end
    
    
    multiplier = (2 / (period + 1) )

    return ((@data[date][:close] - previousEma) * multiplier + previousEma).round(2)

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
      :startDate=>self.startDate, 
      :endDate=>self.endDate,
      :symbol=>self.symbol,
      :csv=>self.csv,
      :data=>self.data
    }
  end


  def to_json(options = {})
    return to_hash.to_json
  end
  def to_s
    return to_hash.to_s
  end
end