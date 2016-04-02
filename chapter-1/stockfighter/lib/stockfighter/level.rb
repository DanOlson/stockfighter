module Stockfighter
  class Level
    LEVEL_URLS = {
      chock_a_block: 'gm/levels/chock_a_block',
      sell_side: 'gm/levels/sell_side'
    }

    class << self
      def chock_a_block
        new :chock_a_block
      end

      def sell_side
        new :sell_side
      end
    end

    attr_reader :level, :connection

    def initialize(level, connection: default_connection)
      @level = level
      @connection = connection
    end

    def start!
      response = connection.post level_urls[level]

      data = JSON.parse response.body
      raise("Couldn't start level: #{level}") unless data['ok']

      configure! data
      puts "#{level} started!"
      puts "Account: #{Stockfighter.settings.account}"
      puts "Venue: #{Stockfighter.settings.venue}"
      puts "Symbol: #{Stockfighter.settings.symbol}"
      puts "Instance ID: #{Stockfighter.settings.instance_id}"
      self
    end

    def stop!
      instance_id = Stockfighter.settings.instance_id
      connection.post "/gm/instances/#{instance_id}/stop"
      puts "Level #{level} stopped!"
    end

    def orderbook
      OrderBook.get connection: connection
    end

    private

    def level_urls
      LEVEL_URLS
    end

    def default_connection
      Connection.new Stockfighter.settings.api_key
    end

    def configure!(response_body)
      Stockfighter.configure do |c|
        c.account     = response_body['account']
        c.venue       = response_body['venues'][0]
        c.symbol      = response_body['tickers'][0]
        c.instance_id = response_body['instanceId']
        c.level       = self
      end
    end
  end
end
