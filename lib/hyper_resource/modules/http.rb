require 'faraday'
require 'uri'
require 'json'
require 'digest/md5'

class HyperResource

  ## Returns this resource's fully qualified URL.  Returns nil when
  ## `root` or `href` are malformed.
  def url
    begin
      URI.join(self.root, (self.href || '')).to_s
    rescue StandardError
      nil
    end
  end


  ## Performs a GET request to this resource's URL, and returns a
  ## new resource representing the response.
  def get
    to_link.get
  end

  ## Performs a GET request to this resource's URL, and returns a
  ## `Faraday::Response` object representing the response.
  def get_response
    to_link.get_response
  end

  ## Performs a POST request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a new resource representing the response.
  def post(attrs=nil)
    to_link.post(attrs)
  end

  ## Performs a POST request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a `Faraday::Response` object representing the response.
  def post_response(attrs=nil)
    to_link.post_response(attrs)
  end

  ## Performs a PUT request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a new resource representing the response.
  def put(*args)
    to_link.put(*args)
  end

  ## Performs a PUT request to this resource's URL, sending all of
  ## `attributes` as a request body unless an `attrs` Hash is given.
  ## Returns a `Faraday::Response` object representing the response.
  def put_response(*args)
    to_link.put_response(*args)
  end

  ## Performs a PATCH request to this resource's URL, sending
  ## `attributes.changed_attributes` as a request body
  ## unless an `attrs` Hash is given.  Returns a new resource
  ## representing the response.
  def patch(*args)
    self.to_link.patch(*args)
  end

  ## Performs a PATCH request to this resource's URL, sending
  ## `attributes.changed_attributes` as a request body
  ## unless an `attrs` Hash is given.
  ## Returns a `Faraday::Response` object representing the response.
  def patch_response(*args)
    self.to_link.patch_response(*args)
  end

  ## Performs a DELETE request to this resource's URL.  Returns a new
  ## resource representing the response.
  def delete
    to_link.delete
  end

  ## Performs a DELETE request to this resource's URL.
  ## Returns a `Faraday::Response` object representing the response.
  def delete_response
    to_link.delete_response
  end

  ## Creates a Link representing this resource.  Used for HTTP delegation.
  # @private
  def to_link(args={})
    self.class::Link.new(self,
                         :href => args[:href] || self.href,
                         :params => args[:params] || self.attributes)
  end



  # @private
  def create(attrs)
    _hr_deprecate('HyperResource#create is deprecated. Please use '+
                  '#post instead.')
    to_link.post(attrs)
  end

  # @private
  def update(*args)
    _hr_deprecate('HyperResource#update is deprecated. Please use '+
                  '#put or #patch instead.')
    to_link.put(*args)
  end

  module Modules

    ## HyperResource::Modules::HTTP is included by HyperResource::Link.
    ## It provides support for GET, POST, PUT, PATCH, and DELETE.
    ## Each method returns a new object which is a kind_of HyperResource.
    module HTTP

      ## Loads and returns the resource pointed to by +href+.  The returned
      ## resource will be blessed into its "proper" class, if
      ## +self.class.namespace != nil+.
      def get
        new_resource_from_response(self.get_response)
      end

      ## Performs a GET request on the given link, and returns the
      ## response as a `Faraday::Response` object.
      ## Does not parse the response as a `HyperResource` object.
      def get_response
        ## Adding default_attributes to URL query params is not automatic
        url = FuzzyURL.new(self.url || '')
        query_str = url[:query] || ''
        query_attrs = Hash[ query_str.split('&').map{|p| p.split('=')} ]
        attrs = (self.resource.default_attributes || {}).merge(query_attrs)
        attrs_str = attrs.inject([]){|pairs,(k,v)| pairs<<"#{k}=#{v}"}.join('&')
        if attrs_str != ''
          url = FuzzyURL.new(url.to_hash.merge(:query => attrs_str))
        end
        faraday_connection.get(url.to_s)
      end

      ## By default, calls +post+ with the given arguments. Override to
      ## change this behavior.
      def create(*args)
        _hr_deprecate('HyperResource::Link#create is deprecated. Please use '+
                      '#post instead.')
        post(*args)
      end

      ## POSTs the given attributes to this resource's href, and returns
      ## the response resource.
      def post(attrs=nil)
        new_resource_from_response(post_response(attrs))
      end

      ## POSTs the given attributes to this resource's href, and returns the
      ## response as a `Faraday::Response` object.
      ## Does not parse the response as a `HyperResource` object.
      def post_response(attrs=nil)
        attrs ||= self.resource.attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.post do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        response
      end

      ## By default, calls +put+ with the given arguments.  Override to
      ## change this behavior.
      def update(*args)
        _hr_deprecate('HyperResource::Link#update is deprecated. Please use '+
                      '#put or #patch instead.')
        put(*args)
      end

      ## PUTs this resource's attributes to this resource's href, and returns
      ## the response resource.  If attributes are given, +put+ uses those
      ## instead.
      def put(attrs=nil)
        new_resource_from_response(put_response(attrs))
      end

      ## PUTs this resource's attributes to this resource's href, and returns
      ## the response as a `Faraday::Response` object.
      ## Does not parse the response as a `HyperResource` object.
      def put_response(attrs=nil)
        attrs ||= self.resource.attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.put do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        response
      end

      ## PATCHes this resource's changed attributes to this resource's href,
      ## and returns the response resource.  If attributes are given, +patch+
      ## uses those instead.
      def patch(attrs=nil)
        new_resource_from_response(patch_response(attrs))
      end

      ## PATCHes this resource's changed attributes to this resource's href,
      ## and returns the response as a `Faraday::Response` object.
      ## Does not parse the response as a `HyperResource` object.
      def patch_response(attrs=nil)
        attrs ||= self.resource.attributes.changed_attributes
        attrs = (self.resource.default_attributes || {}).merge(attrs)
        response = faraday_connection.patch do |req|
          req.body = self.resource.adapter.serialize(attrs)
        end
        response
      end

      ## DELETEs this resource's href, and returns the response resource.
      def delete
        new_resource_from_response(delete_response)
      end

      ## DELETEs this resource's href, and returns the response as a
      ## `Faraday::Response` object.
      ## Does not parse the response as a `HyperResource` object.
      def delete_response
        faraday_connection.delete
      end

    private

      ## Returns a raw Faraday connection to this resource's URL, with proper
      ## headers (including auth).  Threadsafe.
      def faraday_connection(url=nil)
        rsrc = self.resource
        url ||= self.url
        headers = (rsrc.headers_for_url(url) || {}).merge(self.headers)
        auth = rsrc.auth_for_url(url) || {}

        key = ::Digest::MD5.hexdigest({
          'faraday_connection' => {
            'url' => url,
            'headers' => headers,
            'ba' => auth[:basic]
          }
        }.to_json)
        return Thread.current[key] if Thread.current[key]

        fo = rsrc.faraday_options_for_url(url) || {}
        fc = Faraday.new(fo.merge(:url => url))
        fc.headers.merge!('User-Agent' => rsrc.user_agent)
        fc.headers.merge!(headers)
        if ba=auth[:basic]
          fc.basic_auth(*ba)
        end
        Thread.current[key] = fc
      end


      ## Given a Faraday::Response object, create a new resource
      ## object to represent it.  The new resource will be in its
      ## proper class according to its configured `namespace` and
      ## the response's detected data type.
      def new_resource_from_response(response)
        status = response.status
        is_success = (status / 100 == 2)
        adapter = self.resource.adapter || HyperResource::Adapter::HAL_JSON

        body = nil
        unless empty_body?(response.body)
          begin
              body = adapter.deserialize(response.body)
          rescue StandardError => e
            if is_success
              raise HyperResource::ResponseError.new(
                        "Error when deserializing response body",
                        :response => response,
                        :cause => e
                    )
            end

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

      def empty_body?(body)
        return true if body.nil?
        return true if body.respond_to?(:empty?) && body.empty?
        return true if body.class == String && body  =~ /^['"]+$/ # special case for status code with optional body, example Grape API with status 405
        false
      end

    end
  end
end

