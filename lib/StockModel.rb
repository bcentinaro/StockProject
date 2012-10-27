require 'net/http'
require 'csv'
# Only needed for JSON output
require 'json'


class StockModel
  attr_reader :startDate, :endDate, :symbol, :csvData, :data
  def initialize(symbol, daysHistory)
    
  end

  #Persistance Functions
  def save(path, format)
    
  end


  # Serialization functions
  def to_hash()
    return {
      :startDate=>self.startDate, 
      :endDate=>self.endDate,
      :symbol=>self.symbol,
      :csvData=>self.csvData,
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