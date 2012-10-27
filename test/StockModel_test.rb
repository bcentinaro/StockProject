require 'test/unit'
require_relative '../lib/StockModel'

class StockModelTest  < Test::Unit::TestCase
    #After sleeping on it, it's easier to let the modal handle how
    #it's initialized.
    def test_init
      stock = StockModel.new('goog', 100, 5)
      assert stock.endDate == Date.today , 'checking end date'
    end

    def test_persistance
      FileUtils.rm ['/tmp/goog.csv','/tmp/goog.json'], :force=>true 
      stock = StockModel.new('goog', 100, 5)
      stock.save('/tmp/goog', 'csv')
      stock.save('/tmp/goog', 'json')

      
      assert File.exist?('/tmp/goog.csv'), 'Checking CVS output'
      assert File.exist?('/tmp/goog.json'), 'Checking JSON output'
    end

    #Test the Calculation for the SMA
    def test_calcSMA
      stock = StockModel.new('goog', 100, 5)
      sma = stock.sma("2012-10-25",1)
      assert sma == 677.76, "Checking 1 Day SMA. Value: #{sma}, Expected: 677.76"
      sma = stock.sma("2012-10-25",5)
      assert sma == 679.17, "Checking 5 Day SMA. Value: #{sma}, Expected:679.17"
      sma = stock.sma("2012-10-25",10)
      assert sma == 707.68, "Checking 10 Day SMA. Value: #{sma}, Expected:707.68"
      sma = stock.sma("2012-10-25",20)
      assert sma == 732.31, "Checking 20 Day SMA. Value: #{sma}, Expected:732.31"
    end

    #Test the calculation for the EMA
    def test_calcEMA
      stock = StockModel.new('goog', 100, 5)
      date = stock.csv[stock.csv.length - 6][0]
      current = stock.ema(date, 5)
      previous = current
      assert stock.sma(date, 5) == current, 'testing SMA = first EMA'
      10.times do |x|
        date = stock.csv[stock.csv.length - (6 + x)][0]
        previous = current
        current = stock.ema(date,5)
        multiplier = (2 / (5 + 1) )
        expected = ((stock.data[date][:close] - previous) * multiplier + previous).round(2)

        assert current == expected, "Testing 5 Day EMA: #{current} Expected: #{expected}"
      end
    end
    
end