Example usage:

```ruby
module RemoteExpress
  module Hub
    include Remotr::Respondable

    def self.all
      respond_with get('/hubs'), 'hubs'
    end

  end
end
```
