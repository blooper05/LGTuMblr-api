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

  HTTP.persistent(URL) do |http|
    json.concat(parse(api_response(http))) while json.size < LIMIT
    json.uniq! { |url| url.split('/', 5)[3] }
  end

  Oj.dump(json)
end

helpers do
  def randomized_timestamp
    now  = Time.now.to_i
    from = now - PERIOD
    rand(from..now)
  end

  def api_response(http)
    params = { api_key: API_KEY,
               filter:  :text,
               tag:     TAGS.sample,
               before:  randomized_timestamp }
    http.use(:auto_inflate).headers('accept-encoding': :gzip)
        .get(URL, params: params)
  end

  def parse(response)
    json = Oj.load(response.body.to_s, mode: :null, symbol_keys: true)

    json[:response].filter_map do |res|
      case res
      in type: 'photo', photos: [*, { alt_sizes: [*, { width: WIDTH, url: }, *] }, *] then url
      else
      end
    end
  end
end
