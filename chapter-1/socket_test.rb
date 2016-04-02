require 'stockfighter'
require 'eventmachine'

Stockfighter.configure do |c|
  c.api_key = YAML.load_file('./config.yml')[:api_key]
end

EM.run {
  Stockfighter::Level.chock_a_block.start!
  ticker = Stockfighter::QuoteTicker.new
  ticker.start do |data|
    puts data
  end
  
  10.times do
    sleep 1
    puts ticker.last_quote
  end
}
