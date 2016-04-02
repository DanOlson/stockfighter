# require 'faye/websocket'
require 'eventmachine'
require 'websocket-eventmachine-client'

ACCOUNT = 'BPB23230921'
VENUE = 'PIVBEX'

EM.run do
  # conn = Faye::WebSocket::Client.new("wss://api.stockfighter.io/ob/api/ws/#{ACCOUNT}/venues/#{VENUE}/tickertape")

  # puts "Status: #{conn.status}"
  # puts "Headers: #{conn.headers}"

  # conn.on :message do |event|
  #   puts event.data
  # end

  # conn.on(:close) { puts "WebSocket closed!" }
  conn = WebSocket::EventMachine::Client.connect(uri: "wss://api.stockfighter.io/ob/api/ws/#{ACCOUNT}/venues/#{VENUE}/tickertape")

  conn.onmessage do |msg, type|
    puts "#{msg}"
  end
end
