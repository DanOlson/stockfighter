module Stockfighter
  class OrderBook
    URI_TEMPLATE = '/ob/api/venues/%<venue>s/stocks/%<symbol>s'

    class << self
      def get(connection: Connection.new(settings.api_key),
              settings: Stockfighter.settings)
        uri  = URI_TEMPLATE % { venue: settings.venue, symbol: settings.symbol }
        response = connection.get uri

        new data: JSON.parse(response.body)
      end
    end

    attr_reader :bids, :asks, :timestamp, :venue, :symbol

    def initialize(data: {})
      @bids      = data['bids']
      @asks      = data['asks']
      @timestamp = data['ts']
      @venue     = data['venue']
      @symbol    = data['symbol']
    end
  end
end
