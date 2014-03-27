require 'hyper_resource/attributes'
require 'hyper_resource/configuration'
require 'hyper_resource/exceptions'
require 'hyper_resource/link'
require 'hyper_resource/links'
require 'hyper_resource/objects'
require 'hyper_resource/response'
require 'hyper_resource/version'

require 'hyper_resource/adapter'
require 'hyper_resource/adapter/hal_json'

require 'hyper_resource/modules/data_type'
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
    return init_from_resource(opts) if opts.kind_of?(HyperResource)

    self.root       = opts[:root] if opts[:root]
    self.href       = opts[:href] #|| ''

    self.auth       = opts[:auth] if opts[:auth]
    self.namespace  = opts[:namespace] if opts[:namespace]
    self.headers    = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                      merge(opts[:headers]     || {})
    self.faraday_options = opts[:faraday_options] ||
                               self.class.faraday_options || {}

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

    self.adapter    = opts[:adapter] || self.class.adapter ||
                      HyperResource::Adapter::HAL_JSON
  end



  ## Creates a new resource given args :link, :resource, :href, :response, :url,
  ## and :body.  Either :link or (:resource and :href and :url) are required.
  def self.new_from(args) # @private
    link = args[:link]
    resource = args[:resource] || link.resource.__getobj__  ## TODO refactor
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
    new_rsrc = new_class.new(:root => old_rsrc.root, :href => href)
    new_rsrc.hr_config = old_rsrc.hr_config.clone
    new_rsrc.response = response
    new_rsrc.body = body
    new_rsrc.adapter.apply(body, new_rsrc)
    new_rsrc.loaded = true
    new_rsrc
  end

  def new_from(args) # @private
    self.class.new_from(args)
  end


  ## Creates a Link representing this resource.  Used for HTTP delegation.
  def to_link(args={}) # @private
    self.class::Link.new(self,
                         :href => args[:href] || self.href,
                         :params => args[:params] || self.attributes)
  end



  ## Delegate HTTP methods to link.
  def get(*args)
    self.to_link.get(*args)
  end

  def post(*args)
    self.to_link.post(*args)
  end

  def patch(*args)
    self.to_link.patch(*args)
  end

  def put(*args)
    self.to_link.put(*args)
  end

  def delete(*args)
    self.to_link.delete(*args)
  end

  def create(*args)
    self.to_link.create(*args)
  end

  def update(*args)
    self.to_link.update(*args)
  end


  def url
    begin
      URI.join(self.root, self.href).to_s
    rescue StandardError
      nil
    end
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
      return attributes[method] if attributes && attributes[method]
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


  #def inspect # @private
    #"#<#{self.class}:0x#{"%x" % self.object_id} @root=#{self.root.inspect} "+
    #"@href=#{self.href.inspect} @loaded=#{self.loaded} "+
    #"@namespace=#{self.namespace.inspect} ...>"
  #end

  ## +response_body+, +response_object+, and +deserialized_response+
  ##  are deprecated in favor of +body+.  (Sorry. Naming things is hard.)
  def response_body # @private
    _hr_deprecate('HyperResource#response_body is deprecated. '+
                  'Please use HyperResource#body instead.')
    body
  end
  def response_object # @private
    _hr_deprecate('HyperResource#response_object is deprecated. '+
                  'Please use HyperResource#body instead.')
    body
  end
  def deserialized_response # @private
    _hr_deprecate('HyperResource#deserialized_response is deprecated. '+
                  'Please use HyperResource#body instead.')
    body
  end





  def self.user_agent # @private
    "HyperResource #{HyperResource::VERSION}"
  end

  def user_agent # @private
    self.class.user_agent
  end

private

  ## Show a deprecation message.
  def self._hr_deprecate(message) # @private
    STDERR.puts "#{message} (called from #{caller[2]})"
  end

  def _hr_deprecate(*args) # @private
    self.class._hr_deprecate(*args)
  end
end
