require 'test/unit'
require_relative '../lib/StockModel'

class StockModelTest  < Test::Unit::TestCase
    #After sleeping on it, it's easier to let the modal handle how
    #it's initialized.
    def test_init
      stock = StockModel.new('goog', 365)
      assert stock.endDate == Date.today , 'checking end date'
      assert stock.data.length == 365, "Length is: #{stock.data.length}, expected length: 365"
    end

    def test_persistance
      stock = StockModel.new('goog', 365)
      stock.save('/tmp/goog', 'csv')
      stock.save('/tmp/goog', 'json')

      assert File.exist? '/tmp/goog.csv'
      assert File.exist? '/tmp/goog.json'
    end

    #Test the Calculation for the SMA
    def test_calcSMA

    end

    #Test the calculation for the EMA
    def test_calcEMA

    end
    
end