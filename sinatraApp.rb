require 'rubygems'
require 'bundler'
require_relative './lib/StockController'
Bundler.require(:default, ENV['RACK_ENV'].to_sym) 

class MyApp < Sinatra::Application

  
  set :root, File.expand_path('../', __FILE__)  

  #Root URL 
  get '/' do
    haml :root
  end

  #Pre-fetch URL to request stock symbols as they are typed in.
  get '/stock/pre-fetch/:symbols' do
    begin
      @symbols = params[:symbols].gsub(/\s/, '').split('_')
      @period = params[:period]||5
      stockController = StockController.new
      stockController.index(@symbols.join(','), @period)
      return {:error=>'none'}.to_json
    rescue
      #the most likely error is a kick back from yahoo with error page.
      return {:error=>true}.to_json
    end
  end

  #Expects a _ seperated list of symbols
  get '/stock/:symbols/:period?.:format' do
    # First things first, we need to setup variables
    @symbols = params[:symbols].gsub(/\s/, '').split('_')
    @period = params[:period]||5
    @urlBase = "/stock/#{params[:symbols].gsub(/\s/, '')}/#{@period}"
    stockController = StockController.new
    @values = stockController.index(@symbols.join(','), @period)  
    
    
    @values.each do |key, value|
      # Check the existing graph files, delete them if they weren't rendered today
      if File.exist? "./assets/#{key}-month.png"
        if Date.parse(File.ctime("./assets/#{key}-month.png").strftime('%F')) < Date.today
          File.delete "./assets/#{key}-month.png"
          File.delete "./assets/#{key}-90.png"
          File.delete "./assets/#{key}-entire.png"
        end
      end

      #We only need to create new files, IF they don't already exist
      unless File.exist? "./assets/#{key}-month.png"

        graph = Gruff::Line.new
        graph.title ="#{key} - 30 Days" 
        graph.data("ema", value.recentEMA(@period.to_i, 30))
        graph.data("sma", value.recentSMA(@period.to_i, 30))
        graph.data("close", value.recentClosing(30))
        graph.write("./assets/#{key}-month.png")
      
        graph = Gruff::Line.new
        graph.title = "#{key} - 90 Day" 
        graph.data("ema", value.recentEMA(@period.to_i, 90))
        graph.data("sma", value.recentSMA(@period.to_i, 90))
        graph.data("close", value.recentClosing(90))
        graph.write("./assets/#{key}-90.png")

        graph = Gruff::Line.new
        graph.title = "#{key} - Entire History" 
        graph.data("ema", value.recentEMA(@period.to_i, 36500))
        graph.data("sma", value.recentSMA(@period.to_i, 36500))
        graph.data("close", value.recentClosing(36500))
        graph.write("./assets/#{key}-entire.png")
      end
    end

    # We've got json data exposed, should we need it for something
    # like javascript graphs (instead of image graphs)
    if params[:format] == 'json'
      return @values.to_json
    end
    haml :index
  end


  # Expects a _ seperated list of symbols
  get '/stock/:symbols/:period/:date' do 
    @symbols = params[:symbols].gsub(/\s/, '').split('_')
    @period = params[:period]||5
    @urlBase = params[:symbols].gsub(/\s/, '')
    stockController = StockController.new
    stockController.index(@symbols.join(','), @period)
    @values = stockController.show(params[:date])
    haml :show
  end

  #Assets
  get '/assets/*' do |path|
    if File.exist? "assets/#{path}" 
      send_file "assets/#{path}"
    end
  end
end

puts "Running in #{ENV['RACK_ENV']}"