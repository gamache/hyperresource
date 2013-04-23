class HyperResource::Exception < Exception
end

class HyperResource::ClientError < HyperResource::Exception
end

class HyperResource::ServerError < HyperResource::Exception
end

