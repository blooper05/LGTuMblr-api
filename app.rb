# frozen_string_literal: true

require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV'))

URL         = 'https://api.tumblr.com/v2/tagged'
API_KEY     = ENV.fetch('API_KEY')
TAGS        = ENV.fetch('TAGS').split(',')
USER_AGENT  = 'LGTuMblr-api/0.7.0'
PERIOD      = 6 * 30 * 24 * 60 * 60
WIDTH       = 500
CONCURRENCY = 3

class App < Roda
  plugin :json, serializer: ->(o) { Oj.dump(o) }
  plugin :static_routing

  static_get '/images' do
    Tumblr.new.requests
          .flat_map { |response| parse(response) }
          .uniq { |url| url.split('/', 5)[3] }
  end

  plugin :public
  route(&:public)

  private

  def parse(response)
    json = Oj.load(response.body.to_s, mode: :null, symbol_keys: true)

    json[:response].filter_map do |res|
      case res
      in type: 'photo', photos: [*, { alt_sizes: [*, { width: WIDTH, url: }, *] }, *]
        url
      else
        nil
      end
    end
  end
end

class Tumblr
  def initialize
    @client = HTTPX.plugin(:compression)
                   .plugin(:persistent)
                   .plugin(:response_cache)
                   .with_headers('user-agent': USER_AGENT)
  end

  def requests
    requests = Array.new(CONCURRENCY) { [:get, URL, { params: }] }
    @client.request(requests)
  end

  private

  def params
    { api_key: API_KEY,
      filter:  :text,
      tag:     TAGS.sample,
      before:  randomized_timestamp }
  end

  def randomized_timestamp
    now  = Time.now.to_i
    from = now - PERIOD
    rand(from..now)
  end
end
