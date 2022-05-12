# frozen_string_literal: true

require 'bundler'
Bundler.require

URL         = 'https://api.tumblr.com/v2/tagged'
API_KEY     = ENV.fetch('API_KEY')
TAGS        = ENV.fetch('TAGS').split(',')
PERIOD      = 6 * 30 * 24 * 60 * 60
WIDTH       = 500
CONCURRENCY = 3

configure { set :server, :falcon }

get '/images' do
  content_type :json

  image_urls = http_requests.flat_map { |response| parse(response) }
  image_urls.uniq! { |url| url.split('/', 5)[3] }

  Oj.dump(image_urls)
end

helpers do
  def randomized_timestamp
    now  = Time.now.to_i
    from = now - PERIOD
    rand(from..now)
  end

  def params
    { api_key: API_KEY,
      filter:  :text,
      tag:     TAGS.sample,
      before:  randomized_timestamp }
  end

  def http
    HTTPX.plugin(:compression)
         .plugin(:persistent)
         .plugin(:response_cache)
  end

  def http_requests
    requests = Array.new(CONCURRENCY) { [:get, URL, { params: }] }
    http.request(requests)
  end

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
