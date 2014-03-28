class HyperResource
  module Modules
    module Deprecations

      def included(klass)
        klass.extend(ClassMethods)
      end

      ## +response_body+, +response_object+, and +deserialized_response+
      ##  are deprecated in favor of +body+.  (Sorry. Naming things is hard.)
      def response_body # @private
        _hr_deprecate('HyperResource#response_body is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end
      def response_object # @private
        _hr_deprecate('HyperResource#response_object is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end
      def deserialized_response # @private
        _hr_deprecate('HyperResource#deserialized_response is deprecated. '+
                      'Please use HyperResource#body instead.')
        body
      end


      module ClassMethods

      private

        ## Show a deprecation message.
        def self._hr_deprecate(message) # @private
          STDERR.puts "#{message} (called from #{caller[2]})"
        end

        def _hr_deprecate(*args) # @private
          self.class._hr_deprecate(*args)
        end

      end

    end
  end
end

