require 'hyper_resource/version'
require 'hyper_resource/http'
require 'hyper_resource/attributes'
require 'hyper_resource/links'
require 'hyper_resource/link'
require 'hyper_resource/objects'
require 'hyper_resource/request'
require 'hyper_resource/response'

require 'hyper_resource/utils'

require 'net/http'
require 'uri'

class HyperResource

  inheritable_attr :root
  inheritable_attr :auth
  inheritable_attr :headers

  attr_accessor    :root,
                   :href,
                   :auth,
                   :headers,

                   :request,
                   :response,

                   :attributes,
                   :links,
                   :objects


  def initialize(opts={})
    self.root    = opts[:root] || self.class.root

    self.auth    = (self.class.auth   ||{}).merge(opts[:auth]   ||{})
    self.headers = (self.class.headers||{}).merge(opts[:headers]||{})

    self.attributes = Attributes.new
    self.links      = Links.new(self)
    self.objects    = Objects.new
  end

  ## Returns a new HyperResource based on the given HAL document.
  def new_from_hal_response(obj)
    rsrc = self.class.new(root: self.root,
                          auth: self.auth,
                          headers: self.headers,
                          href: obj['_links']['self']['href'])
    rsrc.response = Response[obj]
    rsrc.init_from_response!
    rsrc
  end

  ## Returns a new HyperResource based on the given link href.
  def new_from_link(href)
    rsrc = self.class.new(root: self.root,
                          auth: self.auth,
                          headers: self.headers,
                          href: href)
  end

  ## Loads the resource pointed to by +href+.
  def get
    uri = URI.join(self.root, self.href)
    req = Net::HTTP::Get.new(uri)
    if ba=self[:auth][:basic]
      req.basic_auth *ba
    end
    resp = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    self.response = Response[ JSON.parse(response.body) ]
    init_from_response!
  end

  ## Populates +attributes+, +links+, and +objects+ from the contents of
  ## +response+.
  def init_from_response!
    raise ArgumentError, "response is empty!" unless self.response
    self.attributes.init_from_hal(self.response);
    self.links.init_from_hal(self.response);
    self.objects.init_from_hal(self.response);
    self
  end

end
