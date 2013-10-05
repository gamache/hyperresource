#!/usr/bin/env ruby
require 'sinatra'
require 'json'

class LiveTestServer < Sinatra::Base

  get '/' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Root'
    <<-EOT
      { "name": "whatever API",
        "_links": {
          "self": {"href":"/"},
          "widgets": {"href":"/widgets"}
        }
      }
    EOT
  end

  get '/widgets' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=WidgetSet'
    <<-EOT
      { "name": "My Widgets",
        "_links": {
          "self": {"href":"/widgets"},
          "root": {"href":"/"}
        },
        "_embedded": {
          "widgets": [
            { "name": "Widget 1",
              "_links": {
                "self": {"href": "/widgets/1"},
                "widgets": {"href": "/widgets"}
              }
            }
          ]
        }
      }
    EOT
  end

  put '/widgets/1' do
    params = JSON.parse(request.env["rack.input"].read)
    if params["name"] != 'Awesome Widget dood'
      headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Error'
      [422, JSON.dump({:error => "Name was wrong; you sent #{params.inspect}"})]
    else
      headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Widget'
      <<-EOT
        { "name": "#{params["name"]}",
          "_links": {
            "self": {"href": "/widgets/1"},
            "widgets": {"href": "/widgets"}
          }
        }
      EOT
    end
  end

  post '/widgets' do
    params = JSON.parse(request.env["rack.input"].read)
    if params["name"] != 'Cool Widget brah'
      headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Error'
      [422, JSON.dump(:error => "Name was wrong; you sent #{params.inspect}")]
    else
      headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Widget'
      [201, headers, <<-EOT ]
        { "name": "#{params["name"]}",
          "_links": {
            "self": {"href":"/widgets/2"},
            "widgets": {"href": "/widgets"},
            "root": {"href":"/"}
          }
        }
      EOT
    end
  end

  delete '/widgets/1' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Message'
    <<-EOT
      { "message": "Deleted widget.",
        "_links": {
          "self": {"href":"/widgets/1"},
          "widgets": {"href": "/widgets"},
          "root": {"href":"/"}
        }
      }
    EOT
  end

end

