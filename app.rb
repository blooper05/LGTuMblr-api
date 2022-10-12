# frozen_string_literal: true

require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV'))

URL         = 'https://api.tumblr.com/v2/tagged'
API_KEY     = ENV.fetch('API_KEY')
TAGS        = ENV.fetch('TAGS').split(',')
USER_AGENT  = 'LGTuMblr-api/0.6.0'
PERIOD      = 6 * 30 * 24 * 60 * 60
WIDTH       = 500
CONCURRENCY = 3

class App < Hanami::API
  get '/images' do
    headers['content-type'] = 'application/json'

    image_urls = http_requests.flat_map { |response| parse(response) }
    image_urls.uniq! { |url| url.split('/', 5)[3] }

    Oj.dump(image_urls)
  end

  helpers do
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

  helpers do
    private

    def http
      HTTPX.plugin(:compression)
           .plugin(:persistent)
           .plugin(:response_cache)
           .with_headers('user-agent': USER_AGENT)
    end

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
end
