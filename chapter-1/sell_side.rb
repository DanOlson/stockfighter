require 'stockfighter'
require 'eventmachine'
require 'logger'
require 'logvisible'

CONFIG = YAML.load_file('./config.yml')

Stockfighter.configure do |config|
  config.api_key = CONFIG[:api_key]
end

class TradingStrategy
  include Logvisible::LogMethods
  attr_reader :trader, :logger, :stats, :work_queue

  def initialize(logger: Logger.new(STDOUT), stats: Stats.new(logger), work_queue:)
    @work_queue = work_queue
    @logger = logger
    @stats  = stats
    @trader = Stockfighter::Trader.new
  end

  def implement!
    place_orders get_price

    Thread.new do
      loop do
        order = work_queue.pop
        price = stats.record_order order
        cancel_outstanding_orders!
        place_orders price
      end
    end
  end

  def get_price
    logger.info "Getting a price..."
    quote = Stockfighter::Quote.get
    quote.last || get_price
  end

  def place_orders(price)
    logger.info "Using price: #{price}"
    stats.record_current_price price
    place_asks(calculate_spread price * 1.2) if should_sell?
    place_bids(calculate_spread(price)[0..-2]) if should_buy?
  end

  def should_sell?
    stats.position > -100
  end

  def should_buy?
    stats.position < 100
  end

  def place_bids(spread)
    logger.info "Placing bids with spread: #{spread}"
    spread.each do |price|
      order = trader.bid! price: price, qty: trade_quantity
      stats.record_order order
    end
  end

  def place_asks(spread)
    logger.info "Placing asks with spread: #{spread}"
    spread.each do |price|
      order = trader.ask! price: price, qty: trade_quantity
      stats.record_order order
    end
  end

  def trade_quantity
    100
  end

  def calculate_spread(price)
    [
      price - price * 0.05,
      price,
      price + price * 0.05,
    ].map &:to_i
  end

  ###
  # TODO: May want to throttle this back to orders with zero fills
  def cancel_outstanding_orders!
    open_orders = Stockfighter::Order.all_open
    logvisible "Canceling #{open_orders.size} orders...", sep: '', text: { color: :red }
    num_threads = open_orders.size / 10 + 1
    threads = []
    open_orders.each_slice(num_threads) do |slice|
      threads << Thread.new { slice.map &:cancel }
    end
    threads.each &:join
  end
end

class Stats
  attr_reader :logger, :current_price, :orders
  include Logvisible::LogMethods

  def initialize(logger: Logger.new(STDOUT))
    @orders        = { bids: Hash.new([]), asks: Hash.new([]) }
    @current_price = 0
    @logger        = logger
    @lock          = Mutex.new
  end

  def record_current_price(price)
    @lock.synchronize do
      @current_price = price
    end
  end

  def record_buy(order)
    fills = Array(order.fills)
    return if fills.empty?
    existing_fills = orders[:bids][order.id]
    if fills_already_recorded?(fills, existing_fills)
      logvisible "fills already recorded", sep: '', text: { color: :cyan }
      return
    end

    shares_changed = sum_fill_quantity(fills) - sum_fill_quantity(existing_fills)
    if !shares_changed.zero?
      msg = "BOUGHT on order ID #{order.id}. Shares changed: #{shares_changed}. Price: #{order.price}\n"
      fills.each do |fill|
        msg << "\t\t\tFILL: price: #{fill['price']}, qty: #{fill['qty']}\n"
      end
      logvisible msg, sep: '', text: { color: :cyan }

      new_fills = fills - existing_fills
      if new_fills.all? { |fill| fill['price'] < order.price }
        new_price = new_fills.map { |fill| fill['price'] }.min
        logvisible "Setting new price: #{new_price}", sep: '', text: { color: :cyan, style: :bold }
      end
    end
    orders[:bids][order.id] = fills
    new_price if new_price
  end

  def record_sell(order)
    fills = Array(order.fills)
    return if fills.empty?
    existing_fills = orders[:asks][order.id]
    if fills_already_recorded?(fills, existing_fills)
      logvisible "fills already recorded", sep: '', text: { color: :green }
      return
    end

    shares_changed = sum_fill_quantity(fills) - sum_fill_quantity(existing_fills)
    if !shares_changed.zero?
      rest = {}
      if fills.any? { |f| f['price'] > order.price }
        rest = { style: :bold }
      end
      msg = "SOLD on order ID #{order.id}. Shares changed: #{shares_changed}. Price: #{order.price}\n"
      fills.each do |fill|
        msg << "\t\t\tFILL: price: #{fill['price']}, qty: #{fill['qty']}\n"
      end
      logvisible msg, sep: '', text: { color: :green }.merge(rest)

      new_fills = fills - existing_fills
      if new_fills.all? { |fill| fill['price'] > order.price }
        new_price = new_fills.map { |fill| fill['price'] }.max
        logvisible "Setting new price: #{new_price}", sep: '', text: { color: :green, style: :bold }
      end
    end
    orders[:asks][order.id] = fills
    new_price if new_price
  end

  def fills_already_recorded?(new_fills, existing_fills)
    existing_fills & new_fills == new_fills
  end

  def record_order(order)
    @lock.synchronize do
      new_price = send "record_#{order.direction}", order
      log_stats
      new_price || order.price
    end
  end

  def position
    num_shares_bought = sum_fill_quantity orders[:bids].values
    num_shares_sold   = sum_fill_quantity orders[:asks].values
    num_shares_bought - num_shares_sold
  end

  def cash
    spent  = sum_fill_values orders[:bids].values
    earned = sum_fill_values orders[:asks].values
    earned - spent
  end

  def profit
    current_net_asset_value - basis
  end

  def current_net_asset_value
    cash + (position * current_price)
  end

  ###
  # The amount I've spent
  def basis
    cash < 0 ? cash.abs : 0
  end

  def sum_fill_quantity(fills)
    fills.flatten.reduce(0) { |acc, fill| acc + fill['qty'] }
  end

  def sum_fill_values(fills)
    fills.flatten.reduce(0) do |acc, fill|
      acc + (fill['qty'] * fill['price'])
    end
  end

  def log_stats
    logvisible "Cash: #{cash.to_f / 100}, position: #{position}, NAV: #{current_net_asset_value.to_f / 100}, profit: #{profit.to_f / 100}", sep: '', text: { color: :yellow }
  end
end

class LevelRunner
  attr_reader :logger, :stats, :strategy_class, :work_queue
  include Logvisible::LogMethods

  def initialize(strategy_class: default_strategy_class)
    @work_queue = Queue.new
    @logger = Logger.new(STDOUT)
    @stats  = Stats.new logger: logger
    @strategy_class = strategy_class
    configure_logging
  end

  def run
    Stockfighter::Level.sell_side.start!
    monitor_executions
    trade
  end

  private

  def configure_logging
    formatter = Logger::Formatter.new
    logger.formatter = proc do |_, datetime, _, msg|
      "[#{datetime.strftime('%H:%M:%S.%L')}] #{msg}\n" 
    end
    Logvisible.configure do |c|
      c.logger = logger
    end
  end

  def default_strategy_class
    TradingStrategy
  end

  def trading_strategy
    @trading_strategy ||= strategy_class.new(logger: logger, stats: stats, work_queue: work_queue)
  end

  def monitor_executions
    Stockfighter::ExecutionTape.new.start do |order|
      work_queue.push order
    end
  end

  def trade
    trading_strategy.implement!
  end
end

Thread.abort_on_exception = true
EM.run { LevelRunner.new.run }
