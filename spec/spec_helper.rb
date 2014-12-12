require 'webmock/rspec'
require 'remotr'

module MyTestApp
  include Remotr::Configurable
end

MyTestApp.configure do |config|
  config.base_uri        = 'https://example.com'
  config.api_key         = 'abcdef'
  config.api_version     = 1
  config.base_path       = "/api/v#{config.api_version}"
  config.default_timeout = 0.2
end

module MyTestApp
  module Event
    include Remotr::Respondable

    def self.all
      respond_with get('/events'), :events
    end

    def self.first
      respond_with get('/events/1'), :event
    end
  end
end

RSpec.configure do |config|
  config.before do
    WebMock.enable!
  end
end
