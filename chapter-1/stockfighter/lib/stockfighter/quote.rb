module Stockfighter
  class Quote
    class << self
      extend Forwardable
      def_delegators :settings, :level, :venue, :symbol
      def_delegators :level, :connection

      def get
        new parsed_response "/ob/api/venues/#{venue}/stocks/#{symbol}/quote"
      end

      private

      def parsed_response(url)
        response = connection.get url
        JSON.parse response.body
      end

      def settings
        Stockfighter.settings
      end

      def level
        settings.level
      end
    end

    attr_accessor :symbol,
                  :venue,
                  :bid,
                  :ask,
                  :bid_size,
                  :ask_size,
                  :last,
                  :last_size,
                  :last_trade,
                  :quote_time

    def initialize(data={})
      @symbol     = data['symbol']
      @venue      = data['venue']
      @bid        = data['bid']
      @ask        = data['ask']
      @bid_size   = data['bidSize']
      @ask_size   = data['askSize']
      @last       = data['last']
      @last_size  = data['lastSize']
      @last_trade = Date.parse(data['lastTrade']) if data['lastTrade']
      @quote_time = Date.parse(data['quoteTime']) if data['quoteTime']
    end
  end
end
