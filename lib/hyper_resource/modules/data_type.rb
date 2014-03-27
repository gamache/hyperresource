class HyperResource
  module Modules
    module DataType

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def get_data_type_class(args)
        self.class.get_data_type_class(args)
      end

      def get_data_type(args)
        self.class.get_data_type(args)
      end

      module ClassMethods

        ## Args are :resource, :link, :response, :body, :url.
        def get_data_type_class(args)
          type = get_data_type(args)
          return self unless type

          url = args[:url] || args[:link].url
          namespace = args[:resource].namespace_for_url(url)
          return self unless namespace

          ## Make sure namespace class exists
          namespace_str = sanitize_class_name(namespace.to_s)
          if namespace.kind_of?(String)
            ns_class = eval(namespace_str) rescue nil
            if !ns_class
              Object.module_eval("class #{namespace_str} < #{self}; end")
            end
          end

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

        def get_data_type(args)
          type = get_data_type_from_body(args[:body])
          type ||= get_data_type_from_response(args[:response])
        end

        def get_data_type_from_response(response)
          return nil unless response
          return nil unless content_type = response['content-type']
          return nil unless m=content_type.match(/;\s* type=([0-9A-Za-z:]+)/x)
          m[1]
        end

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
