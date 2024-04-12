# frozen_string_literal: true

class Tumblr
  URL         = 'https://api.tumblr.com/v2/tagged'
  API_KEY     = ENV.fetch('API_KEY')
  TAGS        = ENV.fetch('TAGS').split(',')
  USER_AGENT  = 'LGTuMblr-api/0.7.1'
  PERIOD      = 6 * 30 * 24 * 60 * 60
  CONCURRENCY = 3

  def initialize
    @client = HTTPX.plugin(:brotli)
                   .plugin(:persistent)
                   .plugin(:response_cache)
                   .with_headers('user-agent': USER_AGENT)
  end

  def requests
    requests = Array.new(CONCURRENCY) { ['GET', URL, { params: }] }
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
