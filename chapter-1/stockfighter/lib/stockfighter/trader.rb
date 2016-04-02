require 'forwardable'

module Stockfighter
  class Trader
    ORDERS_URI_TEMPLATE = '/ob/api/venues/%<venue>s/stocks/%<stock>s/orders'
    BUY = 'buy'
    SELL = 'sell'

    extend Forwardable
    attr_reader :connection
    def_delegators :@settings, :account, :venue, :symbol

    def initialize(settings: Stockfighter.settings, connection: Connection.new(settings.api_key))
      @settings   = settings
      @connection = connection
    end

    def bid!(price:, qty:, order_type: 'limit')
      response = connection.post(orders_uri) do |req|
        req.body = JSON.generate({
          account: account,
          venue: venue,
          stock: symbol,
          price: price,
          qty: qty,
          direction: BUY,
          orderType: order_type
        })
      end
      Order.new JSON.parse response.body
    end

    def ask!(price:, qty:, order_type: 'limit')
      response = connection.post(orders_uri) do |req|
        req.body = JSON.generate({
          account: account,
          venue: venue,
          stock: symbol,
          price: price,
          qty: qty,
          direction: SELL,
          orderType: order_type
        })
      end
      Order.new JSON.parse response.body
    end

    private

    def orders_uri
      ORDERS_URI_TEMPLATE % { venue: venue, stock: symbol }
    end
  end
end
