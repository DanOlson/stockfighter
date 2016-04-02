module Stockfighter
  class Order
    class << self
      extend Forwardable
      def_delegators :settings, :level, :venue, :symbol, :account
      def_delegators :level, :connection

      def all
        order_data = parsed_response "/ob/api/venues/#{venue}/accounts/#{account}/orders"
        order_data['orders'].map { |data| new data }
      end

      def all_open
        all.select &:open?
      end

      def find(id)
        new parsed_response "/ob/api/venues/#{venue}/stocks/#{symbol}/orders/#{id}"
      end

      def cancel(id)
        connection.delete "/ob/api/venues/#{venue}/stocks/#{symbol}/orders/#{id}"
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

    ATTRIBUTES = [
      :id,
      :symbol,
      :venue,
      :direction,
      :original_quantity,
      :quantity,
      :price,
      :order_type,
      :account,
      :timestamp,
      :fills,
      :total_filled,
      :open
    ]

    attr_accessor *ATTRIBUTES
    alias_method :open?, :open

    def initialize(data={})
      @id           = data['id']
      @symbol       = data['symbol']
      @venue        = data['venue']
      @direction    = data['direction']
      @price        = data['price']
      @quantity     = data['qty']
      @order_type   = data['orderType']
      @account      = data['account']
      @timestamp    = data['ts']
      @fills        = data['fills']
      @total_filled = data['totalFilled']
      @open         = data['open']
    end

    def cancel
      self.class.cancel id
    end
  end
end
