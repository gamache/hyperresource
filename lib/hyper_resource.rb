require 'hyper_resource/version'
require 'hyper_resource/attributes'
require 'hyper_resource/links'
require 'hyper_resource/link'
require 'hyper_resource/objects'
require 'hyper_resource/response'

require 'hyper_resource/modules/utils'
require 'hyper_resource/modules/http'
require 'hyper_resource/modules/bless'

require 'pp'

class HyperResource
  include HyperResource::Modules::Utils
  include HyperResource::Modules::HTTP
  include HyperResource::Modules::Bless

private

  def self._hr_class_attributes
    %w( root auth headers namespace ).map(&:to_sym)
  end

  def self._hr_attributes
    %w( root href auth headers
        request response response_body
        attributes links objects ).map(&:to_sym)
  end

public

  _hr_class_attributes.each {|attr| class_attribute attr}
  _hr_attributes.each       {|attr| attr_accessor   attr}

  DEFAULT_HEADERS = {
    'Accept' => 'application/json'
  }

  def initialize(opts={})
    if opts.is_a?(HyperResource)
      self.class._hr_attributes.each {|attr| self.send("#{attr}=".to_sym, opts.send(attr))}
      return
    end

    self.root    = opts[:root] || self.class.root
    self.href    = opts[:href] || ''
    self.auth    = (self.class.auth || {}).merge(opts[:auth] || {})
    self.headers = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                   merge(opts[:headers]     || {})

    self.attributes = Attributes.new(self)
    self.links      = Links.new(self)
    self.objects    = Objects.new(self)
  end

  ## Returns a new HyperResource based on the given HyperResource object.
  def new_from_resource(rsrc); self.class.new_from_resource(rsrc) end
  def self.new_from_resource(rsrc)
    new_rsrc = self.new
    _hr_attributes.each do |attr|
      new_rsrc.send("#{attr}=".to_sym, rsrc.send(attr))
    end
    new_rsrc
  end

  ## Returns a new HyperResource based on the given HAL document.
  def new_from_hal(obj)
    rsrc = self.class.new(:root    => self.root,
                          :auth    => self.auth,
                          :headers => self.headers,
                          :href    => obj['_links']['self']['href'])
    rsrc.response_body = Response[obj]
    rsrc.init_from_response_body!
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
  def init_from_response_body!
    return unless self.response_body
    self.objects.   init_from_hal(self.response_body);
    self.links.     init_from_hal(self.response_body);
    self.attributes.init_from_hal(self.response_body);
    self
  end

  ## method_missing will attempt to delegate to +attributes+, then +objects+,
  ## then +links+.  When it finds a match, it will define a method class-wide
  ## if self.class != HyperResource, instance-wide otherwise.
  def method_missing(method, *args)
    [:attributes, :objects, :links].each do |field|
      if self.send(field).respond_to?(method)
        if self.class == HyperResource
          define_singleton_method(method) do |*args|
            self.send(field).send(method, *args)
          end
        else
          self.class.send(:define_method, method) do |*args|
            self.send(field).send(method, *args)
          end
        end
        return self.send(field).send(method, *args)
      end
    end
    super
  end

end
