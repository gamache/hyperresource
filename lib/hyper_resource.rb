require 'hyper_resource/attributes'
require 'hyper_resource/exceptions'
require 'hyper_resource/link'
require 'hyper_resource/links'
require 'hyper_resource/objects'
require 'hyper_resource/response'
require 'hyper_resource/version'

require 'hyper_resource/adapter'
require 'hyper_resource/adapter/hal_json'

require 'hyper_resource/modules/http'
require 'hyper_resource/modules/internal_attributes'

require 'rubygems' if RUBY_VERSION[0..2] == '1.8'

require 'pp'

## HyperResource is the main resource base class.  Normally it will be used
## through subclassing, though it may also be used directly.

class HyperResource

  include HyperResource::Modules::HTTP
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

    self.root       = opts[:root] || self.class.root
    self.href       = opts[:href] || ''
    self.auth       = (self.class.auth || {}).merge(opts[:auth] || {})
    self.namespace  = opts[:namespace] || self.class.namespace
    self.headers    = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                      merge(opts[:headers]     || {})
    self.faraday_options = opts[:faraday_options] ||
                               self.class.faraday_options || {}

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
  ## Override with care.
  def method_missing(method, *args)
    self.get unless self.loaded

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


  def inspect # @private
    "#<#{self.class}:0x#{"%x" % self.object_id} @root=#{self.root.inspect} "+
    "@href=#{self.href.inspect} @loaded=#{self.loaded} "+
    "@namespace=#{self.namespace.inspect} ...>"
  end

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



  ## Return a new HyperResource based on this object and a given href.
  def _hr_new_from_link(href) # @private
    self.class.new(:root            => self.root,
                   :auth            => self.auth,
                   :headers         => self.headers,
                   :namespace       => self.namespace,
                   :faraday_options => self.faraday_options,
                   :href            => href)
  end


  ## Returns the class into which the given response should be cast.
  ## If the object is not loaded yet, or if +namespace+ is
  ## not set, returns +self+.
  ##
  ## Otherwise, +response_class+ uses +get_data_type_from_response+ to
  ## determine subclass name, glues it to the given namespace, and
  ## creates the class if it's not there yet. E.g., given a namespace of
  ## +FooAPI+ and a response content-type of
  ## "application/vnd.foocorp.fooapi.v1+json;type=User", this should
  ## return +FooAPI::User+ (even if +FooAPI::User+ hadn't existed yet).
  def self.response_class(response, namespace)
    if self.to_s == 'HyperResource'
      return self unless namespace
    end

    namespace ||= self.to_s

    type_name = self.get_data_type_from_response(response)
    return self unless type_name

    namespaced_class(type_name, namespace)
  end

  def self.namespaced_class(type_name, namespace)
    class_name = "#{namespace}::#{type_name}"
    class_name.gsub!(/[^_0-9A-Za-z:]/, '')  ## sanitize class_name

    ## Return data type class if it exists
    klass = eval(class_name) rescue :sorry_dude
    return klass if klass.is_a?(Class)

    ## Data type class didn't exist -- create namespace (if necessary),
    ## then the data type class
    if namespace != ''
      nsc = eval(namespace) rescue :bzzzzzt
      unless nsc.is_a?(Class)
        Object.module_eval "class #{namespace} < #{self}; end"
      end
    end
    Object.module_eval "class #{class_name} < #{namespace}; end"
    eval(class_name)
  end

  def _hr_response_class # @private
    self.namespace ||= self.class.to_s unless self.class.to_s=='HyperResource'
    self.class.response_class(self.response, self.namespace)
  end


  ## Inspects the given Faraday::Response, and returns a string describing
  ## this resource's data type.
  ##
  ## By default, this method looks for a +type=...+ modifier in the
  ## response's +Content-type+ and returns that value, capitalized.
  ##
  ## Override this method in a subclass to alter HyperResource's behavior.
  def self.get_data_type_from_response(response)
    return nil unless response
    return nil unless content_type = response['content-type']
    return nil unless m=content_type.match(/;\s* type=([0-9A-Za-z:]+)/x)
    m[1][0,1].upcase + m[1][1..-1]
  end

  ## Uses +HyperResource.get_response_data_type+ to determine the proper
  ## data type for this object.  Override to change behavior (though you
  ## probably just want to override the class method).
  def get_data_type_from_response
    self.class.get_data_type_from_response(self.response)
  end

private

  ## Return this object, "cast" into its proper response class.
  def to_response_class
    response_class = self._hr_response_class
    return self if self.class == response_class
    response_class.new(self)
  end

  ## Use the given resource's data to initialize this one.
  def init_from_resource(resource)
    (self.class._hr_attributes - [:attributes, :links, :objects]).each do |attr|
      self.send("#{attr}=".to_sym, resource.send(attr))
    end
    self.adapter.apply(self.body, self)
  end


  ## Show a deprecation message.
  def self._hr_deprecate(message) # @private
    STDERR.puts "#{message} (called from #{caller[2]})"
  end

  def _hr_deprecate(*args) # @private
    self.class._hr_deprecate(*args)
  end
end
