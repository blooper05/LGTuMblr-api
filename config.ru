# frozen_string_literal: true

require './app'
run App.freeze.app

use Rack::Cors do
  allow do
    origins  '*'
    resource '*', headers: :any, methods: :get
  end
end

use Rack::Deflater
use Rack::ETag

Sentry.init do |config|
  config.breadcrumbs_logger = %i[sentry_logger http_logger]
  config.traces_sample_rate = 0.5

  config.capture_exception_frame_locals = true
  config.send_client_reports            = false
end

use Sentry::Rack::CaptureExceptions
