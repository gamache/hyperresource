require 'faraday'
require 'uri'
require 'json'


module HyperResource::Modules::HTTP

  ## Loads and returns the resource pointed to by +href+.  The returned
  ## resource will be blessed into its "proper" class, if
  ## +self.class.namespace != nil+.
  def get
    self.response = faraday_connection.get(self.href || '')
    finish_up
  end

  ## Returns a per-thread Faraday connection for this object.
  def faraday_connection(url=nil)
    url ||= self.root
    key = "faraday_connection_#{url}"
    return Thread.current[key] if Thread.current[key]

    fc = Faraday.new(:url => url)
    fc.headers.merge!('User-Agent' => "HyperResource #{HyperResource::VERSION}")
    fc.headers.merge!(self.headers || {})
    if ba=self.auth[:basic]
      fc.basic_auth(*ba)
    end
    Thread.current[key] = fc
  end

private

  def finish_up
    self.response_body = JSON.parse(self.response.body)
    self.init_from_response_body!
    self.blessed
  end

end
