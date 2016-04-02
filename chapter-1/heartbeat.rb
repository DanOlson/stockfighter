require 'faraday'
require 'yaml'

API_KEY = YAML.load_file('./config.yml')[:api_key]

conn = Faraday.new(url: 'https://api.stockfighter.io') do |f|
  f.request  :url_encoded 
  f.response :logger
  f.adapter Faraday.default_adapter
end

response = conn.get do |req|
  req.url '/ob/api/heartbeat'
  req.headers['x-starfighter-authorization'] = API_KEY
  req.headers['accept'] = 'application/json'
end

puts response.body
