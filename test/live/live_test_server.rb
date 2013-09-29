#!/usr/bin/env ruby
require 'sinatra'
require 'json'

class LiveTestServer < Sinatra::Base

  get '/' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Root'
    JSON.dump(
      { name: "whatever API",
        _links: {
          self: {href:"/"},
          widgets: {href:"/widgets"}
        }
      }
    )
  end

  get '/widgets' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=WidgetSet'
    JSON.dump(
      { name: "My Widgets",
        _links: {
          self: {href:"/widgets"},
          root: {href:"/"}
        },
        _embedded: {
          widgets: [
            { name: "Widget 1",
              _links: {
                self: {href: "/widgets/1"},
                widgets: {href: "/widgets"}
              }
            }
          ]
        }
      }
    )
  end

end

