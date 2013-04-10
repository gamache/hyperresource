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
    %w( root href auth headers namespace
        request response response_body
        attributes links objects loaded).map(&:to_sym)
  end

public

  _hr_class_attributes.each {|attr| class_attribute attr}
  _hr_attributes.each       {|attr| attr_accessor   attr}

  # :nodoc:
  DEFAULT_HEADERS = {
    'Accept' => 'application/json'
  }

  ## Create a new HyperResource, given a hash of options.  These options
  ## include:
  ##
  ## [root]  The root URL of the resource.
  ##
  ## [auth]  Authentication information.  Currently only +{basic:
  ##         ['key', 'secret']}+ is supported.
  ##
  ## [namespace] Class or class name, into which resources should be
  ##             instantiated.
  ##
  ## [headers] Headers to send along with requests for this resource (as
  ##           well as its eventual child resources, if any).
  def initialize(opts={})
    if opts.is_a?(HyperResource)
      self.class._hr_attributes.each {|attr| self.send("#{attr}=".to_sym, opts.send(attr))}
      return
    end

    self.root       = opts[:root] || self.class.root
    self.href       = opts[:href] || ''
    self.auth       = (self.class.auth || {}).merge(opts[:auth] || {})
    self.namespace  = opts[:namespace] || self.class.namespace
    self.headers    = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                      merge(opts[:headers]     || {})

    self.attributes = Attributes.new(self)
    self.links      = Links.new(self)
    self.objects    = Objects.new(self)
    self.loaded     = false
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
                          :namespace => self.namespace,
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
                          :namespace => self.namespace,
                          :href    => href)
  end

  ## Populates +attributes+, +links+, and +objects+ from the contents of
  ## +response+. Sets +loaded = true+.
  def init_from_response_body!
    return unless self.response_body
    self.objects.   init_from_hal(self.response_body);
    self.links.     init_from_hal(self.response_body);
    self.attributes.init_from_hal(self.response_body);
    self.loaded = true
    self
  end

  ## Returns the first object in the first collection of objects embedded
  ## in this resource.  Equivalent to +self.objects.first+.
  def first; self.objects.first end

  ## Returns the *i*th object in the first collection of objects embedded
  ## in this resource.  Equivalent to +self.objects[i]+.
  def [](i); self.objects.ith(i) end

  ## method_missing will load this resource if not yet loaded, then 
  ## attempt to delegate to +attributes+, then +objects+,
  ## then +links+.  When it finds a match, it will define a method class-wide
  ## if self.class != HyperResource, instance-wide otherwise.
  def method_missing(method, *args)
    self.get unless self.loaded

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


  def inspect # :nodoc:
    "#<#{self.class}:0x#{"%x" % self.object_id} @root=#{self.root.inspect} "+
    "@href=#{self.href.inspect} @loaded=#{self.loaded} "+
    "@namespace=#{self.namespace.inspect} ...>"
  end

end
