require 'hyper_resource/version'
require 'hyper_resource/attributes'
require 'hyper_resource/links'
require 'hyper_resource/link'
require 'hyper_resource/objects'
require 'hyper_resource/response'
require 'hyper_resource/exceptions'

require 'hyper_resource/modules/utils'
require 'hyper_resource/modules/http'

require 'hyper_resource/adapter'
require 'hyper_resource/adapter/hal_json'

require 'pp'


class HyperResource
  include HyperResource::Modules::Utils
  include HyperResource::Modules::HTTP

private

  def self._hr_class_attributes
    [ :root,             ## e.g. 'https://example.com/api/v1'
      :auth,             ## e.g. {:basic => ['username', 'password']}
      :headers,          ## e.g. {'Accept' => 'application/vnd.example+json'}
      :namespace,        ## e.g. 'ExampleAPI', or the class ExampleAPI itself
      :adapter           ## subclass of HR::Adapter
    ]
  end

  def self._hr_attributes
    [ :root,
      :href,
      :auth,
      :headers,
      :namespace,
      :adapter,

      :request,
      :response,
      :response_object,

      :attributes,
      :links,
      :objects,

      :loaded
    ]
  end

public

  _hr_class_attributes.each                    {|attr| class_attribute    attr}
  (_hr_attributes & _hr_class_attributes).each {|attr| fallback_attribute attr}
  (_hr_attributes - _hr_class_attributes).each {|attr| attr_accessor      attr}

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

private

  def init_from_resource(resource)
    (self.class._hr_attributes - [:attributes, :links, :objects]).each do |attr|
      self.send("#{attr}=".to_sym, resource.send(attr))
    end
    self.adapter.apply(self.response_object, self)
  end

public

  def changed?(*args)
    attributes.changed?(*args)
  end

  ## Returns a new HyperResource based on the given link href.
  def _new_from_link(href)
    self.class.new(:root    => self.root,
                   :auth    => self.auth,
                   :headers => self.headers,
                   :namespace => self.namespace,
                   :href    => href)
  end

  def to_response_class
    response_class = self.get_response_class
    return self if self.class == response_class
    response_class.new(self)
  end

  def incoming_filter(attr_hash)
    attr_hash
  end

  def outgoing_filter(attr_hash)
    attr_hash
  end

  def get_response_class
    self.namespace ||= self.class.to_s unless self.class.to_s=='HyperResource'
    self.class.get_response_class(self.response, self.namespace)
  end

  ## Returns the class into which the given response should be cast.
  ## If the object is not loaded yet, or if +opts[:namespace]+ is
  ## not set, returns +self+.
  ##
  ## Otherwise, +get_response_class+ uses +get_response_data_type+ to
  ## determine subclass name, glues it to the given namespace, and
  ## creates the class if it's not there yet. E.g., given a namespace of
  ## +FooAPI+ and a response content-type of
  ## "application/vnd.foocorp.fooapi.v1+json;type=User", this should
  ## return +FooAPI::User+ (even if +FooAPI::User+ hadn't existed yet).

  def self.get_response_class(response, namespace)
    if self.to_s == 'HyperResource'
      return self unless namespace
    end

    namespace ||= self.to_s

    type_name = self.get_response_data_type(response)
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


  def get_response_data_type
    self.class.get_response_data_type(self.response)
  end

  ## Inspects the given response, and returns a string describing this
  ## resource's data type.
  ##
  ## By default, this method looks for a +type=...+ modifier in the
  ## response's +Content-type+ and returns that value, capitalized.
  ##
  ## Override this method in a subclass to alter HyperResource's behavior.

  def self.get_response_data_type(response)
    return nil unless response
    return nil unless content_type = response['content-type']
    return nil unless m=content_type.match(/;\s* type=(?<type> [0-9A-Za-z:]+)/x)
    m[:type][0].upcase + m[:type][1..-1]
  end



  ## Returns the first object in the first collection of objects embedded
  ## in this resource.  Equivalent to +self.objects.first+.
  def first; self.objects.first end

  ## Returns the *i*th object in the first collection of objects embedded
  ## in this resource.  Equivalent to +self.objects[i]+.
  def [](i); self.objects.ith(i) end

  ## method_missing will load this resource if not yet loaded, then 
  ## attempt to delegate to +attributes+, then +objects+, then +links+.
  def method_missing(method, *args)
    self.get unless self.loaded

    [:attributes, :objects, :links].each do |field|
      if self.send(field).respond_to?(method)
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

  ## +response_body+ is deprecated in favor of +response_object+.
  def response_body; response_object end

end
