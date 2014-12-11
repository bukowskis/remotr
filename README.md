# Remotr

Example usage:

```ruby
module RemoteMyApp
  include Remotr::Configurable
end

RemoteMyApp.configure do |config|
  config.base_uri    = 'https://myapp.example.com'
  config.api_key     = 'abcdef'
  config.api_version = 1
  config.base_path   = "/api/v#{config.api_version}"
end

module RemoteMyApp
  module Event
    include Remotr::Respondable

    def self.all
      respond_with get('/events'), :events
    end
  end
end
```
