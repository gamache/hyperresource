require 'faraday'
require 'uri'
require 'json'
require 'digest/md5'

class HyperResource
  module Modules
    module HTTP

      ## Loads and returns the resource pointed to by +href+.  The returned
      ## resource will be blessed into its "proper" class, if
      ## +self.class.namespace != nil+.
      def get
        self.response = faraday_connection.get(self.href || '')
        finish_up
      end

      ## By default, calls +post+ with the given arguments. Override to
      ## change this behavior.
      def create(*args)
        post(*args)
      end

      ## POSTs the given attributes to this resource's href, and returns
      ## the response resource.
      def post(attrs=nil)
        attrs || self.attributes
        self.response = faraday_connection.post do |req|
          req.body = adapter.serialize(attrs)
        end
        finish_up
      end

      ## By default, calls +put+ with the given arguments.  Override to
      ## change this behavior.
      def update(*args)
        put(*args)
      end

      ## PUTs this resource's attributes to this resource's href, and returns
      ## the response resource.  If attributes are given, +put+ uses those
      ## instead.
      def put(attrs=nil)
        attrs ||= self.attributes
        self.response = faraday_connection.put do |req|
          req.body = adapter.serialize(attrs)
        end
        finish_up
      end

      ## PATCHes this resource's changed attributes to this resource's href,
      ## and returns the response resource.  If attributes are given, +patch+
      ## uses those instead.
      def patch(attrs=nil)
        attrs ||= self.attributes.changed_attributes
        self.response = faraday_connection.patch do |req|
          req.body = adapter.serialize(attrs)
        end
        finish_up
      end

      ## DELETEs this resource's href, and returns the response resource.
      def delete
        self.response = faraday_connection.delete
        finish_up
      end

      ## Returns a raw Faraday connection to this resource's URL, with proper
      ## headers (including auth).  Threadsafe.
      def faraday_connection(url=nil)
        url ||= URI.join(self.root, self.href)
        key = Digest::MD5.hexdigest({
          'faraday_connection' => {
            'url' => url,
            'headers' => self.headers,
            'ba' => self.auth[:basic]
          }
        }.to_json)
        return Thread.current[key] if Thread.current[key]

        fc = Faraday.new(self.faraday_options.merge(:url => url))
        fc.headers.merge!('User-Agent' => "HyperResource #{HyperResource::VERSION}")
        fc.headers.merge!(self.headers || {})
        if ba=self.auth[:basic]
          fc.basic_auth(*ba)
        end
        Thread.current[key] = fc
      end

    private

      def finish_up
        begin
          self.body = self.adapter.deserialize(self.response.body) unless self.response.body.nil?
        rescue StandardError => e
          raise HyperResource::ResponseError.new(
            "Error when deserializing response body",
            :response => self.response,
            :cause => e
          )
        end

        self.adapter.apply(self.body, self)
        self.loaded = true

        status = self.response.status
        if status / 100 == 2
          return to_response_class
        elsif status / 100 == 3
          ## TODO redirect logic?
        elsif status / 100 == 4
          raise HyperResource::ClientError.new(status.to_s,
                                               :response => self.response,
                                               :body => self.body)
        elsif status / 100 == 5
          raise HyperResource::ServerError.new(status.to_s,
                                               :response => self.response,
                                               :body => self.body)

        else ## 1xx? really?
          raise HyperResource::ResponseError.new("Got status #{status}, wtf?",
                                                 :response => self.response,
                                                 :body => self.body)

        end
      end

    end
  end
end

