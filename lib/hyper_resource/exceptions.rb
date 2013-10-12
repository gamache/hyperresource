class HyperResource
  class Exception < ::StandardError
    attr_accessor :cause            # Internal exception which led to this

    def initialize(message, opts={})
      self.cause = opts[:cause]
      super
    end
  end

  class ResponseError < Exception
    attr_accessor :response         # Response body which led to this
    attr_accessor :response_object  # Response object which led to this

    def initialize(message, opts={})
      self.response = opts[:response]
      self.response_object = opts[:response_object]

      ## Try to help out with the message
      if self.response_object
        if error = self.response_object['error']
          message = "#{message} (#{error})"
        end
      elsif self.response
        message = "#{message} (\"#{self.response.inspect}\")"
      end

      super(message, opts)
    end
  end

  class ClientError < ResponseError; end
  class ServerError < ResponseError; end
end

