require 'test/unit'
require_relative '../lib/StockController'


#Technically a functional test, but TestUnit can work
class StockControllerTest  < Test::Unit::TestCase

    def test_index
        controller = StockController.new
        assert controller.index('goog,fb', 5).length == 2
    end

    def test_show
        controller = StockController.new
        controller.index('goog,fb', 5)
        assert controller.show('10-24-2012').length == 2
    end

end