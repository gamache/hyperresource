this_dir = File.dirname(__FILE__)
Dir.glob(this_dir + '/hyper_resource/**/*.rb') {|f| require f}

if RUBY_VERSION[0..2] == '1.8'
  require 'rubygems'
end

require 'pp'

class HyperResource
  include HyperResource::Modules::Utils
  include HyperResource::Modules::HTTP
  include Enumerable

private

  def self._hr_class_attributes # @private
    [ :root,             ## e.g. 'https://example.com/api/v1'
      :auth,             ## e.g. {:basic => ['username', 'password']}
      :headers,          ## e.g. {'Accept' => 'application/vnd.example+json'}
      :namespace,        ## e.g. 'ExampleAPI', or the class ExampleAPI itself
      :adapter           ## subclass of HR::Adapter
    ]
  end

  def self._hr_attributes # @private
    [ :root,
      :href,
      :auth,
      :headers,
      :namespace,
      :adapter,

      :request,
      :response,
      :deserialized_response,

      :attributes,
      :links,
      :objects,

      :loaded
    ]
  end

public

  _hr_class_attributes.each                    {|attr| _hr_class_attribute    attr}
  (_hr_attributes & _hr_class_attributes).each {|attr| _hr_fallback_attribute attr}
  (_hr_attributes - _hr_class_attributes).each {|attr| attr_accessor          attr}

  # @private
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
    return init_from_resource(opts) if opts.kind_of?(HyperResource)

    self.root       = opts[:root] || self.class.root
    self.href       = opts[:href] || ''
    self.auth       = (self.class.auth || {}).merge(opts[:auth] || {})
    self.namespace  = opts[:namespace] || self.class.namespace
    self.headers    = DEFAULT_HEADERS.merge(self.class.headers || {}).
                                      merge(opts[:headers]     || {})

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


public

  ## Returns true if one or more of this object's attributes has been
  ## reassigned.
  def changed?(*args)
    attributes.changed?(*args)
  end

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

  ## +response_body+ and +response_object+ are deprecated in favor of
  ## +deserialized_response+.  (Sorry. Naming things is hard.)
  def response_body # @private
    _hr_deprecate('HyperResource#response_body is deprecated. Please use '+
                  'HyperResource#deserialized_response instead.')
    deserialized_response
  end
  def response_object # @private
    _hr_deprecate('HyperResource#response_object is deprecated. Please use '+
                  'HyperResource#deserialized_response instead.')
    deserialized_response
  end


  #######################################################################
  ####   Underscored functions are not meant to be used outside of   ####
  ####   HyperResource machinery.  You have been warned.             ####


  ## Return a new HyperResource based on this object and a given href.
  def _new_from_link(href) # @private
    self.class.new(:root    => self.root,
                   :auth    => self.auth,
                   :headers => self.headers,
                   :namespace => self.namespace,
                   :href    => href)
  end


  ## Returns the class into which the given response should be cast.
  ## If the object is not loaded yet, or if +opts[:namespace]+ is
  ## not set, returns +self+.
  ##
  ## Otherwise, +_get_response_class+ uses +_get_response_data_type+ to
  ## determine subclass name, glues it to the given namespace, and
  ## creates the class if it's not there yet. E.g., given a namespace of
  ## +FooAPI+ and a response content-type of
  ## "application/vnd.foocorp.fooapi.v1+json;type=User", this should
  ## return +FooAPI::User+ (even if +FooAPI::User+ hadn't existed yet).

  def self._get_response_class(response, namespace) # @private
    if self.to_s == 'HyperResource'
      return self unless namespace
    end

    namespace ||= self.to_s

    type_name = self._get_response_data_type(response)
    return self unless type_name

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

  def _get_response_class # @private
    self.namespace ||= self.class.to_s unless self.class.to_s=='HyperResource'
    self.class._get_response_class(self.response, self.namespace)
  end


  ## Inspects the given response, and returns a string describing this
  ## resource's data type.
  ##
  ## By default, this method looks for a +type=...+ modifier in the
  ## response's +Content-type+ and returns that value, capitalized.
  ##
  ## Override this method in a subclass to alter HyperResource's behavior.

  def self._get_response_data_type(response)
    return nil unless response
    return nil unless content_type = response['content-type']
    return nil unless m=content_type.match(/;\s* type=([0-9A-Za-z:]+)/x)
    m[1][0,1].upcase + m[1][1..-1]
  end

  ## Uses +HyperResource.get_response_data_type+ to determine the proper
  ## data type for this object.  Override to change behavior.


  def _get_response_data_type
    self.class._get_response_data_type(self.response)
  end

private

  ## Return this object, "cast" into its proper response class.
  def to_response_class
    response_class = self._get_response_class
    return self if self.class == response_class
    response_class.new(self)
  end

  def init_from_resource(resource)
    (self.class._hr_attributes - [:attributes, :links, :objects]).each do |attr|
      self.send("#{attr}=".to_sym, resource.send(attr))
    end
    self.adapter.apply(self.deserialized_response, self)
  end

end
