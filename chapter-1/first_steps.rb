require 'faraday'
require 'yaml'
require 'json'

ACCOUNT = 'HS91020851'
API_KEY = YAML.load_file('./config.yml')[:api_key]

conn = Faraday.new(url: 'https://api.stockfighter.io') do |f|
  f.request  :url_encoded 
  f.response :logger
  f.adapter Faraday.default_adapter
end

response = conn.post do |req|
  req.url '/ob/api/venues/CMNTEX/stocks/HSL/orders'
  req.headers['x-starfighter-authorization'] = API_KEY
  req.headers['accept'] = 'application/json'

  req.body = JSON.generate({
    account: ACCOUNT,
    venue: 'CMNTEX',
    stock: 'HSL',
    price: 8442,
    qty: 100,
    direction: 'buy',
    orderType: 'limit'
  })
end

puts response.body
