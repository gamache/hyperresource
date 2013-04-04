class HyperResource
  class Base
    class_accessor :root,
                   :default_headers,
                   :default_auth

    attr_accessor  :request,
                   :response,
  end
end
