class HyperResource
  module Modules
    module Deprecations

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      ## Show a deprecation message.
      # @private
      def _hr_deprecate(*args)
        self.class._hr_deprecate(*args)
      end

      module ClassMethods
        ## Show a deprecation message.
        # @private
        def _hr_deprecate(message)
          STDERR.puts "#{message} (called from #{caller[2]})"
        end
      end


      ###### Deprecated stuff:

      ## +response_body+, +response_object+, and +deserialized_response+
      ##  are deprecated in favor of +body+.  (Sorry. Naming things is hard.)
      ## Deprecated at 0.2. @private
      def response_body
        _hr_deprecate('HyperResource#response_body is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end

      # @private
      def response_object
        _hr_deprecate('HyperResource#response_object is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end

      # @private
      def deserialized_response
        _hr_deprecate('HyperResource#deserialized_response is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end


      ## Deprecated at 0.9:
      ## #create, #update, Link#create, Link#update

    end
  end
end

