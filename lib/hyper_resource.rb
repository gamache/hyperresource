require 'hyper_resource/version'
require 'hyper_resource/attributes'
require 'hyper_resource/links'
require 'hyper_resource/link'
require 'hyper_resource/objects'
require 'hyper_resource/response'

require 'hyper_resource/modules/utils'
require 'hyper_resource/modules/http'

require 'net/http'
require 'uri'
require 'json'

require 'pp'

class HyperResource
  include HyperResource::Modules::Utils
  include HyperResource::Modules::HTTP

  class_attribute :root
  class_attribute :auth
  class_attribute :headers

  attr_accessor   :root,
                  :href,
                  :auth,
                  :headers,

                  :request,
                  :response,

                  :attributes,
                  :links,
                  :objects

  DEFAULT_HEADERS = {
    'Accept' => 'application/json'
  }

  def initialize(opts={})
    self.root    = opts[:root] || self.class.root
    self.href    = opts[:href] || ''
    self.auth    = (self.class.auth || {}).merge(opts[:auth] || {})
    self.headers = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                   merge(opts[:headers]     || {})

    self.attributes = Attributes.new(self)
    self.links      = Links.new(self)
    self.objects    = Objects.new(self)
  end

  ## Returns a new HyperResource based on the given HAL document.
  def new_from_hal_response(obj)
    rsrc = self.class.new(:root    => self.root,
                          :auth    => self.auth,
                          :headers => self.headers,
                          :href    => obj['_links']['self']['href'])
    rsrc.response = Response[obj]
    rsrc.init_from_response!
    rsrc
  end

  ## Returns a new HyperResource based on the given link href.
  def new_from_link(href)
    rsrc = self.class.new(:root    => self.root,
                          :auth    => self.auth,
                          :headers => self.headers,
                          :href    => href)
  end

  ## Populates +attributes+, +links+, and +objects+ from the contents of
  ## +response+.
  def init_from_response!
    raise ArgumentError, "response is empty!" unless self.response
    self.objects.init_from_hal(self.response);
    self.links.init_from_hal(self.response);
    self.attributes.init_from_hal(self.response);
    self
  end

end
