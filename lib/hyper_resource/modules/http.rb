require 'faraday'
require 'uri'
require 'json'
require 'digest/md5'

class HyperResource
  module Modules

    ## HyperResource::Modules::HTTP is included by HyperResource::Link.
    ## It provides support for GET, POST, PUT, PATCH, and DELETE.
    ## Each method returns a new object which is a kind_of HyperResource.
    module HTTP

      ## Loads and returns the resource pointed to by +href+.  The returned
      ## resource will be blessed into its "proper" class, if
      ## +self.class.namespace != nil+.
      def get
        response = faraday_connection.get(self.href || '')
        new_resource_from_response(response)
      end

      ## By default, calls +post+ with the given arguments. Override to
      ## change this behavior.
      def create(*args)
        post(*args)
      end

      ## POSTs the given attributes to this resource's href, and returns
      ## the response resource.
      def post(attrs=nil)
        attrs ||= self.resource.attributes
        response = faraday_connection.post do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## By default, calls +puwt+ with the given arguments.  Override to
      ## change this behavior.
      def update(*args)
        put(*args)
      end

      ## PUTs this resource's attributes to this resource's href, and returns
      ## the response resource.  If attributes are given, +put+ uses those
      ## instead.
      def put(attrs=nil)
        attrs ||= self.resource.attributes
        response = faraday_connection.put do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## PATCHes this resource's changed attributes to this resource's href,
      ## and returns the response resource.  If attributes are given, +patch+
      ## uses those instead.
      def patch(attrs=nil)
        attrs ||= self.resource.attributes.changed_attributes
        response = faraday_connection.patch do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        new_resource_from_response(response)
      end

      ## DELETEs this resource's href, and returns the response resource.
      def delete
        response = faraday_connection.delete
        new_resource_from_response(response)
      end

    #private

      ## Returns a raw Faraday connection to this resource's URL, with proper
      ## headers (including auth).  Threadsafe.
      def faraday_connection(url=nil)
        rsrc = self.resource
        url ||= URI.join(rsrc.root, self.href || '')
        key = ::Digest::MD5.hexdigest({
          'faraday_connection' => {
            'url' => url,
            'headers' => rsrc.headers,
            'ba' => rsrc.auth[:basic]
          }
        }.to_json)
        return Thread.current[key] if Thread.current[key]

        fo = rsrc.faraday_options_for_url(url) || {}
        fc = Faraday.new(fo.merge(:url => url))
        fc.headers.merge!('User-Agent' => rsrc.user_agent)
        fc.headers.merge!(rsrc.headers || {})
        if ba=rsrc.auth[:basic]
          fc.basic_auth(*ba)
        end
        Thread.current[key] = fc
      end

      def new_resource_from_response(response)
        status = response.status
        is_success = (status / 100 == 2)

        body = nil
        begin
          if response.body
            body = self.resource.adapter.deserialize(response.body)
          end
        rescue StandardError => e
          if is_success
            raise HyperResource::ResponseError.new(
              "Error when deserializing response body",
              :response => response,
              :cause => e
            )
          end
        end

        new_rsrc = resource.new_from(:link => self,
                                     :body => body,
                                     :response => response)

        if status / 100 == 2
          return new_rsrc
        elsif status / 100 == 3
          raise NotImplementedError,
            "HyperResource has not implemented redirection."
        elsif status / 100 == 4
          raise HyperResource::ClientError.new(status.to_s,
                                               :response => response,
                                               :body => body)
        elsif status / 100 == 5
          raise HyperResource::ServerError.new(status.to_s,
                                               :response => response,
                                               :body => body)
        else ## 1xx? really?
          raise HyperResource::ResponseError.new("Unknown status #{status}",
                                                 :response => response,
                                                 :body => body)

        end
      end

    end
  end
end

