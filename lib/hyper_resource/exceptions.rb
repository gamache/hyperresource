class HyperResource
  class Exception < ::Exception
    attr_accessor :response         # response body which led to this
    attr_accessor :response_object  # response object which led to this
    attr_accessor :cause            # internal exception which led to this

    def initialize(message, opts={})
      self.response = opts[:response]
      self.cause = opts[:cause]

      if self.response_object = opts[:response_object]
        if error = self.response_object['error']
          message = "#{message} (#{error})"
        end
      end

      super(message)
    end
  end

  class ResponseError < Exception; end
  class ClientError   < Exception; end
  class ServerError   < Exception; end
end
