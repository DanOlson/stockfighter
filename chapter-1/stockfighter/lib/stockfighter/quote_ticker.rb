module Stockfighter
  class QuoteTicker
    URL_TEMPLATE = 'wss://api.stockfighter.io/ob/api/ws/%<account>s/venues/%<venue>s/tickertape'

    attr_reader :account, :venue

    def initialize(account: default_account, venue: default_venue)
      @account = account
      @venue  = venue
      @quotes = []
    end

    def start(&callback)
      conn = WebSocket::EventMachine::Client.connect uri: url

      conn.onmessage do |message, type|
        callback.call(message)
      end
    end

    def last_quote
      @quotes.last
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
