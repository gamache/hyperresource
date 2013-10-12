class HyperResource
  class Exception < ::StandardError
    ## The internal exception which led to this one, if any.
    attr_accessor :cause

    def initialize(message, attrs={}) # @private
      self.cause = attrs[:cause]
      super(message)
    end
  end

  class ResponseError < Exception
    ## The +Faraday::Response+ object which led to this exception.
    attr_accessor :response

    ## The deserialized response body which led to this exception.
    ## May be blank, e.g. in case of deserialization errors.
    attr_accessor :deserialized_response

    def initialize(message, attrs={}) # @private
      self.response = attrs[:response]
      self.deserialized_response = attrs[:deserialized_response]

      ## Try to help out with the message
      if self.deserialized_response
        if error = self.deserialized_response['error']
          message = "#{message} (#{error})"
        end
      elsif self.response
        message = "#{message} (\"#{self.response.inspect}\")"
      end

      super(message, attrs)
    end
  end

  class ClientError < ResponseError; end
  class ServerError < ResponseError; end
end

