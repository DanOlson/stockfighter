require 'faraday'
require 'json'
require 'yaml'

API_KEY = YAML.load_file('./config.yml')[:api_key]
SYMBOL = 'AVYO'
VENUE = 'QEOWEX'

conn = Faraday.new(url: 'https://api.stockfighter.io') do |f|
  f.request  :url_encoded 
  f.response :logger
  f.adapter Faraday.default_adapter
end

response = conn.get("/ob/api/venues/#{VENUE}/stocks/#{SYMBOL}") do |req|
  req.headers['x-starfighter-authorization'] = API_KEY
  req.headers['accept'] = 'application/json'
end

puts response.body
