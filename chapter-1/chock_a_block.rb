require 'stockfighter'
require 'logger'

CONFIG = YAML.load_file('./config.yml')

Stockfighter.configure do |config|
  config.api_key = CONFIG[:api_key]
end

class LevelRunner
  attr_accessor :bids, :asks, :logger, :orderbook

  def initialize
    @bids   = {}
    @asks   = {}
    @logger = Logger.new(STDOUT)
  end

  def run!
    level.start!
    trade
  end

  private

  def trade(price=get_price, trade_count=0)
    logger.info "price: #{price}"
    response = buy(price: price, qty: rand(5000))
    order = JSON.parse response.body
    sleep 2
    price = best_fill_price(order) || get_price
    cancel_unfilled_orders if trade_count > 9
    trade(price, trade_count+1)
  end

  def get_price
    get_orderbook
    orderbook.lowest_ask_price
  end

  def get_orderbook
    self.orderbook = loop do
      ob = level.orderbook
      price = ob.lowest_ask_price
      break ob if price
    end
  end

  def buy(price:, qty:)
    trader.bid! price: price, qty: qty
  end

  def sell(price:, qty:)
    trader.ask! price: price, qty: qty
  end

  def bid_price_for(quote)
    quote.bid + 5
  end

  def bid_qty_for(quote)
    # quote.bid_size
    5000
  end

  def ask_price_for(quote)
    quote.ask - 5
  end

  def ask_qty_for(quote)
    quote.ask_size
    5000
  end

  # def trade_for_ten_seconds
  #   quote = 
  #   price = quote.ask
  #   qty   = quote.ask_size
  #   limit = Time.now + 10
  #   while Time.now < limit
  #     if qty.zero?
  #       logger.info "Placing seed trades..."
  #       place_seed_trades
  #     else
  #       logger.info "Bidding -- Price: #{price} : QTY: #{qty}"
  #       response = trader.bid!(price: price, qty: qty)
  #       order = JSON.parse(response.body)
  #     end
  #     price = best_fill_price(order) || price
  #     qty = [qty, rand(5000)].max
  #   end
  # end

  def best_fill_price(order)
    fills = Stockfighter::Order.all_open.flat_map &:fills
    fills += order['fills'] if order
    fills.map { |fill| fill['price'] }.sort[0]
  end

  def cancel_unfilled_orders
    open_orders = Stockfighter::Order.all_open
    unfilled = open_orders.select { |order| order.total_filled == 0 }
    unfilled.each &:cancel
  end

  def level
    @level ||= Stockfighter::Level.chock_a_block
  end

  def trader
    @trader ||= Stockfighter::Trader.new connection: level.connection
  end
end

LevelRunner.new.run!
