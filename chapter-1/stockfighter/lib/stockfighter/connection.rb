module Stockfighter
  class Connection
    BASE_URL = 'https://api.stockfighter.io'
    AUTH_HEADER = 'x-stockfighter-authorization'

    attr_reader :conn, :api_key

    def initialize(api_key)
      @api_key = api_key
      @conn = Faraday.new(url: BASE_URL) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end

    def post(path)
      conn.post do |req|
        req.url path
        req.headers[AUTH_HEADER] = api_key
        req.headers['accept'] = 'application/json'

        yield req if block_given?
      end
    end

    def get(path)
      conn.get do |req|
        req.url path
        req.headers[AUTH_HEADER] = api_key
        req.headers['accept'] = 'application/json'
      end
    end

    def delete(path)
      conn.delete do |req|
        req.url path
        req.headers[AUTH_HEADER] = api_key
        req.headers['accept'] = 'application/json'
      end
    end
  end
end
