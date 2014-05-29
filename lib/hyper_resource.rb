require 'hyper_resource/attributes'
require 'hyper_resource/configuration'
require 'hyper_resource/exceptions'
require 'hyper_resource/link'
require 'hyper_resource/links'
require 'hyper_resource/objects'
require 'hyper_resource/version'

require 'hyper_resource/adapter'
require 'hyper_resource/adapter/hal_json'

require 'hyper_resource/modules/data_type'
require 'hyper_resource/modules/deprecations'
require 'hyper_resource/modules/http'
require 'hyper_resource/modules/config_attributes'
require 'hyper_resource/modules/internal_attributes'

require 'rubygems' if RUBY_VERSION[0..2] == '1.8'

require 'pp'

## HyperResource is the main resource base class.  Normally it will be used
## through subclassing, though it may also be used directly.

class HyperResource

  include HyperResource::Modules::ConfigAttributes
  include HyperResource::Modules::DataType
  include HyperResource::Modules::Deprecations
  include HyperResource::Modules::InternalAttributes
  include Enumerable

private

  DEFAULT_HEADERS = { 'Accept' => 'application/json' }

public

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
  ##
  ## [faraday_options] Configuration passed to +Faraday::Connection.initialize+,
  ##                   such as +{request: {timeout: 30}}+.
  ##
  def initialize(opts={})
    self.root = opts[:root] if opts[:root]
    self.href = opts[:href] if opts[:href]

    self.hr_config = self.class.hr_config.clone

    self.adapter         = opts[:adapter]         if opts[:adapter]
    self.faraday_options = opts[:faraday_options] if opts[:faraday_options]
    self.auth            = opts[:auth]            if opts[:auth]

    self.headers = DEFAULT_HEADERS.
                     merge(self.class.headers || {}).
                     merge(opts[:headers]     || {})

    self.namespace = opts[:namespace] if opts[:namespace]
    if !self.namespace && self.class != HyperResource
      self.namespace = self.class.namespace || self.class.to_s
    end

    ## There's a little acrobatics in getting Attributes, Links, and Objects
    ## into the correct subclass.
    if self.class != HyperResource
      if self.class::Attributes == HyperResource::Attributes
        Object.module_eval(
          "class #{self.class}::Attributes < HyperResource::Attributes; end"
        )
      end
      if self.class::Links == HyperResource::Links
        Object.module_eval(
          "class #{self.class}::Links < HyperResource::Links; end"
        )
      end
      if self.class::Objects == HyperResource::Objects
        Object.module_eval(
          "class #{self.class}::Objects < HyperResource::Objects; end"
        )
      end
    end

    self.attributes = self.class::Attributes.new(self)
    self.links      = self.class::Links.new(self)
    self.objects    = self.class::Objects.new(self)
    self.loaded     = false
  end



  ## Creates a new resource given args :link, :resource, :href, :response, :url,
  ## and :body.  Either :link or (:resource and :href and :url) are required.
  # @private
  def self.new_from(args)
    link = args[:link]
    resource = args[:resource] || link.resource
    href = args[:href] || link.href
    url = args[:url] || URI.join(resource.root, href || '')
    response = args[:response]
    body = args[:body] || {}

    old_rsrc = resource
    new_class = old_rsrc.get_data_type_class(:resource => old_rsrc,
                                             :link => link,
                                             :url => url,
                                             :response => response,
                                             :body => body)
    new_rsrc = new_class.new(:root => old_rsrc.root,
                             :href => href)
    new_rsrc.hr_config = old_rsrc.hr_config.clone
    new_rsrc.response = response
    new_rsrc.body = body
    new_rsrc.adapter.apply(body, new_rsrc)
    new_rsrc.loaded = true
    new_rsrc
  end

  # @private
  def new_from(args)
    self.class.new_from(args)
  end


  ## Returns true if one or more of this object's attributes has been
  ## reassigned.
  def changed?(*args)
    attributes.changed?(*args)
  end


  #### Filters

  ## +incoming_body_filter+ filters a hash of attribute keys and values
  ## on their way from a response body to a HyperResource.  Override this
  ## in a subclass of HyperResource to implement filters on incoming data.
  def incoming_body_filter(attr_hash)
    attr_hash
  end

  ## +outgoing_body_filter+ filters a hash of attribute keys and values
  ## on their way from a HyperResource to a request body.  Override this
  ## in a subclass of HyperResource to implement filters on outgoing data.
  def outgoing_body_filter(attr_hash)
    attr_hash
  end

  ## +outgoing_uri_filter+ filters a hash of attribute keys and values
  ## on their way from a HyperResource to a URL.  Override this
  ## in a subclass of HyperResource to implement filters on outgoing URI
  ## parameters.
  def outgoing_uri_filter(attr_hash)
    attr_hash
  end


  #### Enumerable support

  ## Returns the *i*th object in the first collection of objects embedded
  ## in this resource.  Returns nil on failure.
  def [](i)
    get unless loaded
    self.objects.first[1][i] rescue nil
  end

  ## Iterates over the objects in the first collection of embedded objects
  ## in this resource.
  def each(&block)
    get unless loaded
    self.objects.first[1].each(&block) rescue nil
  end

  #### Magic

  ## method_missing will load this resource if not yet loaded, then
  ## attempt to delegate to +attributes+, then +objects+, then +links+.
  ## Override with extreme care.
  def method_missing(method, *args)
    ## If not loaded, load and retry.
    unless loaded
      return self.get.send(method, *args)
    end


    ## Otherwise, try to match against attributes, then objects, then links.
    method = method.to_s
    if method[-1,1] == '='
      return attributes[method[0..-2]] = args.first if attributes[method[0..-2]]
    else
      return attributes[method] if attributes && attributes.has_key?(method.to_s)
      return objects[method] if objects && objects[method]
      if links && links[method]
        if args.count > 0
          return links[method].where(*args)
        else
          return links[method]
        end
      end
    end

    raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
  end

  ## respond_to? is patched to return +true+ if +method_missing+ would
  ## successfully delegate a method call to +attributes+, +links+, or
  ## +objects+.
  def respond_to?(method, *args)
    return true if self.links && self.links.respond_to?(method)
    return true if self.attributes && self.attributes.respond_to?(method)
    return true if self.objects && self.objects.respond_to?(method)
    super
  end


  def inspect # @private
    "#<#{self.class}:0x#{"%x" % self.object_id} @root=#{self.root.inspect} "+
    "@href=#{self.href.inspect} @loaded=#{self.loaded} "+
    "@namespace=#{self.namespace.inspect} ...>"
  end

  def self.user_agent # @private
    "HyperResource #{HyperResource::VERSION}"
  end

  def user_agent # @private
    self.class.user_agent
  end

end

