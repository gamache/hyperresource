class HyperResource::Exception < Exception
end

class HyperResource::ResponseError < HyperResource::Exception
  attr_reader :response
  def initialize(response = nil)
    @response = response
  end
end

class HyperResource::ClientError < HyperResource::ResponseError
end

class HyperResource::ServerError < HyperResource::ResponseError
end

