# frozen_string_literal: true

require './app'
run Sinatra::Application

use Rack::Cors do
  allow do
    origins  '*'
    resource '*', headers: :any, methods: :get
  end
end

use Rack::ContentLength
use Rack::Deflater
use Rack::ETag

Sentry.init do |config|
  config.breadcrumbs_logger = %i[sentry_logger http_logger]
  config.traces_sample_rate = 0.5
end

use Sentry::Rack::CaptureExceptions
