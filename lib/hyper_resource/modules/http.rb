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
    begin
      self.response_object = self.adapter.deserialize(self.response.body)
    rescue Exception => e
      raise HyperResource::ResponseError.new(
        "Error when deserializing response body",
        :response => self.response,
        :cause => e
      )
    end

    self.adapter.apply(self.response_object, self)
    self.loaded = true

    status = self.response.status
    if status / 100 == 2
      return to_response_class
    elsif status / 100 == 3
      ## TODO redirect logic?
    elsif status / 100 == 4
      raise HyperResource::ClientError.new(status.to_s,
                                           :response => self.response)
    elsif status / 100 == 5
      raise HyperResource::ServerError.new(status.to_s,
                                           :response => self.response)
    else ## 1xx? really?
      raise HyperResource::ResponseError.new("Got status #{status}, wtf?",
                                             :response => self.response)
    end
  end

end
