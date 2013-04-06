require 'net/http'
require 'uri'
require 'json'

module HyperResource::Modules::HTTP
  def self.included(base)
    base.extend(ClassMethods)
  end


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
    self.response = resp
    self.response_body = self.class::Response[ JSON.parse(resp.body) ]
    init_from_response_body!

    ## Return self, blessed into the proper class
    self.blessed
  end

  module ClassMethods
  end

end
