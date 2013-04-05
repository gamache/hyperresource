module HyperResource::Modules
  module HTTP
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      ## Loads the resource pointed to by +href+.
      def get
        uri = URI.join(self.root, self.href||'')
        req = Net::HTTP::Get.new(uri)
        if ba=self.auth[:basic]
          req.basic_auth *ba
        end
        (self.headers || {}).each {|k,v| req[k] = v }

        resp = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end

        self.request  = req
        self.response = Response[ JSON.parse(resp.body) ]
        init_from_response!
      end

    end # module ClassMethods

  end
end
