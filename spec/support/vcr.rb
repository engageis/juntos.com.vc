require 'vcr'

VCR.configure do |config|
   config.cassette_library_dir = File.join(Rails.root,'spec/fixtures/vcr_cassettes')
   config.hook_into :fakeweb
   config.default_cassette_options = { match_requests_on: [:path] }
   config.allow_http_connections_when_no_cassette = true
end
