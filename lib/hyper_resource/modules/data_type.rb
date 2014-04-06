class HyperResource
  module Modules
    module DataType

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # @private
      def get_data_type_class(args)
        self.class.get_data_type_class(args)
      end

      # @private
      def get_data_type(args)
        self.class.get_data_type(args)
      end

      module ClassMethods

        ## Returns the class into which a given response should be
        ## instantiated.  Class name is a combination of `resource.namespace`
        ## and `get_data_type(args)'.  Creates this class if necessary.
        ## Args are :resource, :link, :response, :body, :url.
        # @private
        def get_data_type_class(args)
          pp url = args[:url] || args[:link].url
          namespace = args[:resource].namespace_for_url(url.to_s)
          pp namespace || "no namespace bish"
          return self unless namespace
          pp "had a namespace #{namespace}"

          ## Make sure namespace class exists
          namespace_str = sanitize_class_name(namespace.to_s)
          if namespace.kind_of?(String)
            ns_class = eval(namespace_str) rescue nil
            if !ns_class
              Object.module_eval("class #{namespace_str} < #{self}; end")
              ns_class = eval(namespace_str)
            end
          end

          ## If there's no identifiable data type, return the namespace class.
          type = get_data_type(args)
          return ns_class unless type
          puts "got a data type #{type}"

          ## Make sure data type class exists
          type = type[0,1].upcase + type[1..-1]  ## capitalize
          data_type_str = sanitize_class_name("#{namespace_str}::#{type}")
          data_type_class = eval(data_type_str) rescue nil
          if !data_type_class
            Object.module_eval("class #{data_type_str} < #{namespace_str}; end")
            data_type_class = eval(data_type_str)
          end

          data_type_class
        end

        ## Given a body Hash and a response Faraday::Response, detect and
        ## return a string describing this response's data type.
        ## Args are :body and :response.
        def get_data_type(args)
          type = get_data_type_from_body(args[:body])
          type ||= get_data_type_from_response(args[:response])
        end

        ## Given a Faraday::Response, inspects the Content-type for data
        ## type information and returns data type as a String,
        ## for instance returning `Widget` given a media
        ## type `application/vnd.example.com+hal+json;type=Widget`.
        ## Override this method to change behavior.
        ## Returns nil on failure.
        def get_data_type_from_response(response)
          return nil unless response
          return nil unless content_type = response['content-type']
          return nil unless m=content_type.match(/;\s* type=([0-9A-Za-z:]+)/x)
          m[1]
        end

        ## Given a response body Hash, returns the response's data type as
        ## a string.  By default, it looks for a `_data_type` field in the
        ## response.  Override this method to change behavior.
        def get_data_type_from_body(body)
          return nil unless body
          body['_data_type'] || body['type']
        end

      private

        ## Remove all non-word, non-colon elements from a class name.
        def sanitize_class_name(name)
          name.gsub(/[^_0-9A-Za-z:]/, '')
        end

      end

    end
  end
end
