# frozen_string_literal: true

require 'bundler'
Bundler.require(:default, ENV.fetch('RACK_ENV'))

require './tumblr'

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

  WIDTH = 500

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
