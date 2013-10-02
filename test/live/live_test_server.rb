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

end

