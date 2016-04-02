module Stockfighter
  class ExecutionTape
    URL_TEMPLATE = 'wss://api.stockfighter.io/ob/api/ws/%<account>s/venues/%<venue>s/executions'

    attr_reader :account, :venue

    def initialize(account: default_account, venue: default_venue)
      @account = account
      @venue   = venue
    end

    def start(&callback)
      conn = WebSocket::EventMachine::Client.connect uri: url

      conn.onopen do
        puts "[ExecutionTape] Websocket connection established..."
      end

      conn.onmessage do |message, type|
        parsed = JSON.parse message
        order = Order.new parsed['order']
        yield order
      end

      conn.onclose do |code, reason|
        puts "Websocket connection to execution tape closed! Code: #{code}, Reason: #{reason}"
        start &callback
      end
    end

    private

    def url
      URL_TEMPLATE % { account: account, venue: venue }
    end

    def default_account
      Stockfighter.settings.account
    end

    def default_venue
      Stockfighter.settings.venue
    end
  end
end
