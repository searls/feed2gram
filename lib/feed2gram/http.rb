require "net/http"
require "json"

module Feed2Gram
  class Http
    BASE = "https://graph.facebook.com/v18.0".freeze

    def self.get(path, params = {})
      send(path, :get, params)
    end

    def self.post(path, params = {})
      send(path, :post, params)
    end

    def self.send(path, method, params = {})
      uri = URI("#{BASE}#{path}")
      uri.query = URI.encode_www_form(params)
      res = (method == :get) ? Net::HTTP.get_response(uri) : Net::HTTP.post_form(uri, {})
      data = JSON.parse(res.body, symbolize_names: true)

      if res.is_a?(Net::HTTPSuccess)
        data
      else
        raise Error, data[:error]
      end
    end
  end
end
