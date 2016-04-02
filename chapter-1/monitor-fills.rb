require 'faye/websocket'
require 'eventmachine'

ACCOUNT = 'EDB72894050'
VENUE = 'RUSBEX'
SYMBOL = 'TIK'

EM.run do
  conn = Faye::WebSocket::Client.new("wss://api.stockfighter.io/ob/api/ws/#{ACCOUNT}/venues/#{VENUE}/executions/stocks/#{SYMBOL}")

  puts "Status: #{conn.status}"
  puts "Headers: #{conn.headers}"

  conn.on :message do |event|
    puts event.data
  end

  conn.on(:close) { puts "WebSocket closed!" }
end
