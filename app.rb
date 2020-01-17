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
  json = []

  while json.size < LIMIT
    json += parse(api_response)
    json.uniq! { |url| url.split('/')[3] }
  end

  Oj.dump(json)
end

helpers do
  def randomized_timestamp
    now  = Time.now
    from = now - PERIOD
    rand(from..now).to_i
  end

  def api_response
    params = { api_key: API_KEY,
               filter:  :text,
               tag:     TAGS.sample,
               before:  randomized_timestamp }
    HTTP.get(URL, params: params)
  end

  def parse(response)
    json = Oj.load(response.body.to_s, mode: :null, symbol_keys: true)
    json[:response].flat_map do |res|
      next unless res[:type] == 'photo'

      res[:photos].flat_map do |photo|
        photo[:alt_sizes].map do |size|
          size[:url] if size[:width] == WIDTH
        end
      end
    end.compact
  end
end
