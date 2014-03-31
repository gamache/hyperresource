class HyperResource
  module Modules
    module ConfigAttributes

      ATTRS = [:auth, :headers, :namespace, :adapter, :faraday_options]

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # @private
      def hr_config
        @hr_config ||= self.class::Configuration.new
      end

      # @private
      def hr_config=(cfg)
        @hr_config = cfg
      end

      ## When called with no arguments, returns this resource's Configuration.
      ## When called with a hash, applies the given configuration parameters
      ## to this resource's Configuration.  `hash` must be in the form:
      ##   {'hostmask' => {'key1' => 'value1', 'key2' => 'value2', ...}}
      ## Valid keys are `auth`, `headers`, `namespace`, `adapter`, and
      ## `faraday_options`.
      def config(hash=nil)
        return hr_config unless hash
        hr_config.config(hash)
      end

      ## Returns the auth config hash for this resource.
      def auth
        cfg_get(:auth) || {}
      end

      ## Returns the auth config hash for the given url.
      def auth_for_url(url)
        self.hr_config.get_for_url(url, :auth)
      end

      ## Sets the auth config hash for this resource.
      ## Currently only the format `{:basic => ['username', 'password']}`
      ## is supported.
      def auth=(v)
        cfg_set(:auth, v)
      end

      ## Returns the headers hash for this resource.
      def headers
        cfg_get(:headers) || {}
      end

      ## Returns the headers hash for the given url.
      def headers_for_url(url)
        self.hr_config.get_for_url(url, :headers)
      end

      ## Sets the headers hash for this resource.
      def headers=(v)
        cfg_set(:headers, v)
      end

      ## Returns the namespace string/class for this resource.
      def namespace
        cfg_get(:namespace)
      end

      ## Returns the namespace string/class for the given url.
      def namespace_for_url(url)
        self.hr_config.get_for_url(url, :namespace)
      end

      ## Sets the namespace string/class for this resource.
      def namespace=(v)
        cfg_set(:namespace, v)
      end

      ## Returns the adapter class for this resource.
      def adapter
        cfg_get(:adapter) # || HyperResource::Adapter::HAL_JSON
      end

      ## Returns the adapter class for the given url.
      def adapter_for_url(url)
        self.hr_config.get_for_url(url, :adapter)
      end

      ## Sets the adapter class for this resource.
      def adapter=(v)
        cfg_set(:adapter, v)
      end

      ## Returns the Faraday connection options hash for this resource.
      def faraday_options
        cfg_get(:faraday_options)
      end

      ## Returns the Faraday connection options hash for this resource.
      def faraday_options_for_url(url)
        self.hr_config.get_for_url(url, :faraday_options)
      end

      ## Sets the Faraday connection options hash for this resource.
      def faraday_options=(v)
        cfg_set(:faraday_options, v)
      end


    private

      def cfg_get(key)
        hr_config.get_for_url(self.url, key) ||
          self.class.hr_config.get_for_url(self.url, key)
      end

      def cfg_set(key, value)
        hr_config.set_for_url(self.url, key, value)
      end

    public

      module ClassMethods

        def hr_config
          @hr_config ||= self::Configuration.new
        end

        ## When called with no arguments, returns this class's Configuration.
        ## When called with a hash, applies the given configuration parameters
        ## to this resource's Configuration.  `hash` must be in the form:
        ##   {'hostmask' => {'key1' => 'value1', 'key2' => 'value2', ...}}
        ## Valid keys are `auth`, `headers`, `namespace`, `adapter`, and
        ## `faraday_options`.
        def config(hash=nil)
          return hr_config unless hash
          hr_config.config(hash)
        end

        ## Returns the auth config hash for this resource.
        def auth;     cfg_get(:auth) end

        ## Sets the auth config hash for this resource.
        def auth=(v); cfg_set(:auth, v) end

        ## Returns the headers hash for this resource.
        def headers;     cfg_get(:headers) end

        ## Sets the headers hash for this resource.
        def headers=(v); cfg_set(:headers, v) end

        ## Returns the namespace string/class for this resource.
        def namespace;     cfg_get(:namespace) end

        ## Sets the namespace string/class for this resource.
        def namespace=(v); cfg_set(:namespace, v) end

        ## Returns the adapter class for this resource.
        def adapter;     cfg_get(:adapter) end

        ## Sets the adapter class for this resource.
        def adapter=(v); cfg_set(:adapter, v) end

        ## Returns the Faraday connection options hash for this resource.
        def faraday_options;     cfg_get(:faraday_options) end

        ## Sets the Faraday connection options hash for this resource.
        def faraday_options=(v); cfg_set(:faraday_options, v) end

      private

        def cfg_get(key)
          value = hr_config.get_for_url(self.root, key)
          if value != nil
            value
          elsif superclass.respond_to?(:hr_config)
            superclass.hr_config.get_for_url(self.root, key)
          else
            nil
          end
        end

        def cfg_set(key, value)
          hr_config.set_for_url(self.root, key, value)
        end

      end

    end
  end
end
