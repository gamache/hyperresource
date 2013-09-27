class HyperResource
  class Exception < ::Exception
    attr_accessor :response  # response object which led to this exception
    attr_accessor :cause     # internal exception which led to this exception

    def initialize(message, opts={})
      self.response = opts[:response]
      self.cause = opts[:cause]
      super(message)
    end
  end

  class ResponseError < Exception; end
  class ClientError   < Exception; end
  class ServerError   < Exception; end
end
