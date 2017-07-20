# frozen_string_literal: true

require './app.rb'
run Sinatra::Application

use Rack::Cors do
  allow do
    origins  '*'
    resource '*', headers: :any, methods: :get
  end
end
