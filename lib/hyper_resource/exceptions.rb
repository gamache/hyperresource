class HyperResource::Exception < Exception
end

class HyperResource::ResponseError < HyperResource::Exception
end

class HyperResource::ClientError < HyperResource::ResponseError
end

class HyperResource::ServerError < HyperResource::ResponseError
end

