require "rubygems"
require "bundler/setup"
require './lib/StockController'

#prompt for the stock symbols 
puts "Stock Symbol(s) (comma seperated):"
symbols = gets.chomp

period = 0

while period.to_i == 0
  puts "Period (in days): "
  period = gets.chomp
end

puts "Getting Stock History for #{symbols} for a period of #{period}"

controller = StockController.new
stockData = controller.index(symbols, period)

day = 0

while day != 'exit'
  puts "Select Day (YYYY-MM-DD or exit to exit):"
  day = gets.chomp
  unless day =='exit'
    data = controller.show(day)
    data.each do |key, value|
      puts "Stock: #{key}"
      puts "=============================="
      puts "Close: #{value[:close]}"
      puts "SMA: #{stockData[key].sma(day, period)}"
      puts "EMA: #{stockData[key].ema(day, period).round(2)}"
      puts ""
    end
  end
end