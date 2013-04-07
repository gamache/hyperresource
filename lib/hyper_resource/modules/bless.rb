module HyperResource::Modules::Bless

  ## Returns this resource as an instance of +self.resource_class+.
  ## The returned object will share structure with the source object;
  ## beware.
  def blessed
    return self unless self.namespace
    self.resource_class.new(self)
  end

  ## Returns the class into which this resource should be cast.
  ## If the object is not loaded yet, or if +self.namespace+ is
  ## not set, returns +self.class+.
  ##
  ## Otherwise, +resource_class+ looks at the returned content-type, and 
  ## attempts to match a 'type=...' modifier.  Given a namespace of
  ## +FooAPI+ and a response content-type of
  ## "application/vnd.foocorp.fooapi.v1+json;type=User", this should
  ## return +FooAPI::User+ (even if +FooAPI::User+ hadn't existed yet).
  def resource_class
    return self.class unless self.namespace
    return self.class unless type_name = self.data_type_name
    class_name = "#{self.namespace}::#{type_name}".
                   gsub(/[^_0-9A-Za-z:]/, '')

    ## Return data type class if it exists
    klass = eval(class_name) rescue :sorry_dude
    return klass if klass.is_a?(Class)

    ## Data type class didn't exist -- create namespace (if necessary),
    ## then the data type class
    if self.namespace != ''
      nsc = eval(self.namespace) rescue :bzzzzzt
      unless nsc.is_a?(Class)
        Object.module_eval "class #{self.namespace} < #{self.class}; end"
      end
    end
    Object.module_eval "class #{class_name} < #{self.namespace}; end"
    eval(class_name)
  end

  ## Inspects the response, and returns a string describing this
  ## resource's data type.
  ##
  ## By default, this method looks for a +type=...+ modifier in the
  ## response's +Content-type+.  Override this method in a 
  ## HyperResource subclass in order to implement different data type
  ## detection.
  def data_type_name
    return nil unless self.response
    return nil unless content_type = self.response['content-type']
    return nil unless m=content_type.match(/;\s* type=(?<type> [0-9A-Za-z:]+)/x)
    m[:type][0].upcase + m[:type][1..-1]
  end


end
