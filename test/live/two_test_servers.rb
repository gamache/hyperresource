require 'json'

PORT_ONE = ENV['TEST_PORT_ONE'] || 42774
PORT_TWO = ENV['TEST_PORT_TWO'] || 42775

class ServerOne < Sinatra::Base
  get '/' do
    params = request.env['rack.request.query_hash']
    headers['Content-Type'] = 'application/hal+json'
    <<-EOT
      { "name": "Server One",
        "sent_params": #{JSON.dump(params)},
        "_links": {
          "self":       {"href": "http://localhost:#{PORT_ONE}/"},
          "server_two": {"href": "http://localhost:#{PORT_TWO}/"}
        }
      }
    EOT
  end
end

class ServerTwo < Sinatra::Base
  get '/' do
    params = request.env['rack.request.query_hash']
    headers['Content-Type'] = 'application/hal+json'
    <<-EOT
      { "name": "Server Two",
        "sent_params": #{JSON.dump(params)},
        "_links": {
          "self":       {"href": "http://localhost:#{PORT_TWO}/"},
          "server_one": {"href": "http://localhost:#{PORT_ONE}/"}
        }
      }
    EOT
  end
end

