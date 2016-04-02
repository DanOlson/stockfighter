require 'faraday'
require 'yaml'
require 'json'
require 'date'
require 'websocket-eventmachine-client'

require "stockfighter/version"
require 'stockfighter/settings'
require 'stockfighter/connection'
require 'stockfighter/trader'
require 'stockfighter/order_book'
require 'stockfighter/level'
require 'stockfighter/quote_ticker'
require 'stockfighter/execution_tape'
require 'stockfighter/order'
require 'stockfighter/quote'

module Stockfighter
  class << self
    def configure
      yield settings
    end

    def settings
      @settings ||= Settings.new
    end
  end
end
