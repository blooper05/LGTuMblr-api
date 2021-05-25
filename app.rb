# frozen_string_literal: true

require 'bundler'
Bundler.require

URL     = 'https://api.tumblr.com/v2/tagged'
API_KEY = ENV['API_KEY']
TAGS    = ENV['TAGS'].split(',')
LIMIT   = 10
PERIOD  = 6 * 30 * 24 * 60 * 60
WIDTH   = 500

configure { set :server, :falcon }

get '/images' do
  content_type :json

  json = []
  json.concat(parse(api_response)) while json.size < LIMIT
  json.uniq! { |url| url.split('/')[3] }

  Oj.dump(json)
end

helpers do
  def randomized_timestamp
    now  = Time.now.to_i
    from = now - PERIOD
    rand(from..now)
  end

  def api_response
    params = { api_key: API_KEY,
               filter:  :text,
               tag:     TAGS.sample,
               before:  randomized_timestamp }
    HTTP.use(:auto_inflate).headers('accept-encoding': :gzip)
        .get(URL, params: params)
  end

  def parse(response)
    json = Oj.load(response.body.to_s, mode: :null, symbol_keys: true)

    json[:response].map do |res|
      case res
      in type: 'photo', photos: [*, { alt_sizes: [*, { width: WIDTH, url: }, *] }, *] then url
      else
      end
    end.compact
  end
end
