class HyperResource
  class Exception < ::Exception
    attr_accessor :response         # Response body which led to this
    attr_accessor :response_object  # Response object which led to this
    attr_accessor :cause            # Internal exception which led to this

    def initialize(message, opts={})
      self.response = opts[:response]
      self.response_object = opts[:response_object]
      self.cause = opts[:cause]

      ## Try to help out with the message
      if self.response_object
        if error = self.response_object['error']
          message = "#{message} (#{error})"
        end
      elsif self.response
        message = "#{message} (\"#{self.response.inspect}\")"
      end

      super(message)
    end
  end

  class ResponseError < Exception; end
  class ClientError   < Exception; end
  class ServerError   < Exception; end
end
