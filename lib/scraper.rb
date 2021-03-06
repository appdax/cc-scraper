require 'securerandom'
require 'typhoeus'
require 'stock'
require 'json'
require 'serializer'
require 'gear'

# To scrape all data about a stock from consorsbank.de the Scraper class takes
# a list of of ISIN numbers and a set of fields to scrape for. Once a stock been
# scraped the date gets serialed to JSON string and written down into a file.
#
# @example Scrape intraday data for facebook stock.
#   Scraper.new.run ['US30303M1027'], fields: :PriceV1
#
# @example Scrape all data for facebook stock.
#   Scraper.new.run ['US30303M1027']
#
class Scraper
  # List of valid fields for API v1
  FIELDS = [
    :PerformanceV1,
    :PriceV1,
    :RecommendationV1,
    :ScreenerV1,
    :ScreenerAnalysisV1,
    :TechnicalAnalysisV1,
    :TradingCentralV1,
    :EventsV1,
    :HistoryV1
  ].freeze

  include Gear

  # Intialize the scraper.
  #
  # @example With a custom drop box location.
  #   Scraper.new drop_box: '/Users/katzer/tmp'
  #
  # @param [ String ] drop_box: The folder where to place the stock data.
  #
  # @return [ Fetcher ] A new scraper instance.
  def initialize(drop_box: 'tmp/stocks')
    @drop_box   = drop_box
    @hydra      = Typhoeus::Hydra.new
    @serializer = Serializer.new
  end

  attr_reader :drop_box

  # Run the hydra with the given ISIN numbers to scrape their data.
  #
  # @example Scrape Facebook Inc.
  #   run('US30303M1027')
  #
  # @example Scrape Facebook and Amazon
  #   run('US30303M1027', 'US0231351067')
  #
  # @param [ Array<String> ] isins List of ISIN numbers.
  # @param [ Array<Symbol> ] fields Subset of Scraper::FIELDS.
  # @param [ Int ] concurrent Max number of concurrent requests.
  # @param [ Int ] parallel Max number of stocks per request.
  #
  # @return [ Int ] Total number of scraped stocks.
  def run(isins, fields: FIELDS, concurrent: 200, parallel: 1)
    FileUtils.mkdir_p @drop_box

    return 0 if isins.empty?

    pids, *pipes = run_gear(isins, fields, concurrent, parallel)

    wait_for(pids, timeout: 20)

    sum_scraped_stocks(*pipes)
  end

  private

  # Scrape the content of the stock specified by his ISIN number.
  # The method workd async as the `on_complete` callback of the response
  # object delegates to the fetchers `on_complete` method.
  #
  # @example Scrape Facebook Inc.
  #   scrape('US30303M1027')
  #
  # @param [ Array<String> ] isins Set of ISIN numbers.
  #
  # @return [ Void ]
  def scrape(isins, fields: FIELDS)
    url = url_for(isins, fields)
    req = Typhoeus::Request.new(url)

    req.on_complete(&method(:on_complete))

    @hydra.queue req
  end

  # Callback of the `scrape` method once the request is complete.
  # The containing stocks will be saved to into a file. If the list is
  # paginated then the linked pages will be added to the queue.
  #
  # @param [ Typhoeus::Response ] res The response of the HTTP request.
  #
  # @return [ Void ]
  def on_complete(res)
    data = parse_response(res)

    data.each do |json|
      stock = Stock.new(json, res.effective_url)

      next unless stock.available?

      save_stock_as_json(stock)
      @count += 1
    end
  end

  # Parses the response body to ruby object.
  #
  # @param [ res ] The response with JSON encoded body.
  #
  # @return [ Object ] The parsed ruby object.
  def parse_response(res)
    return [] unless res.success?
    JSON.parse(res.body, symbolize_names: true)
  rescue JSON::ParserError
    []
  end

  # Save the scraped stock data in a file under @drop_box dir.
  #
  # @param [ Stock ] stock
  def save_stock_as_json(stock)
    filepath = File.join(@drop_box, filename_for(stock))
    json     = @serializer.serialize(stock)

    File.open(filepath, 'w+') { |io| io << json } if json
  end

  # Generate a filename for a stock.
  #
  # @example Filename for Facebook stock
  #   filename_for(facebook)
  #   #=> 'facebook-01bff156-5e39-4c13-b35a-8380814ef07f.json'
  #
  # @param [ Stock ] stock The specified stock.
  #
  # @return [ String ] A filename of a JSON file.
  def filename_for(stock)
    "#{stock.isin}-#{SecureRandom.uuid}.json"
  end

  # Build url to request the content of the specified fields of the stock.
  #
  # @example URL to get the basic data only.
  #   url_for 'US30303M1027'
  #   #=> 'stocks?field=BasicV1&id=US30303M1027'
  #
  # @example URL to get the basic and performance data.
  #   url_for 'US30303M1027'
  #   #=> 'stocks?field=BasicV1&field=PerformanceV1&id=US30303M1027'
  #
  # @param [ Array<String> ] isins The ISIN numbers of the specified stock.
  # @param [ Array<Symbol> ] fields A subset of Scraper::FIELDS.
  #
  # @return [ String]
  def url_for(isins, fields = [])
    url = 'https://www.consorsbank.de/ev/rest/de/marketdata/stocks?field=BasicV1'

    fields.each { |field| url << "&field=#{field}" if FIELDS.include? field }

    url << '&range=-1&resolution=1D' if fields.include? :HistoryV1

    isins.each_with_object(url) { |isin, uri| uri << "&id=#{isin}" }
  end
end
