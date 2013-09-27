class HyperResource
  class Links < Hash
    attr_accessor :_resource

    def initialize(resource=nil)
     self._resource = resource || HyperResource.new
    end

    ## Creates accessor methods in self.class and self._resource.class.
    ## Protects against method creation into HyperResource::Links and
    ## HyperResource classes.  Just subclasses, please!
    def create_methods!(opts={})
      return if self.class.to_s == 'HyperResource::Links' ||
                self._resource.class.to_s == 'HyperResource'

      self.keys.each do |attr|
        attr_sym = attr.to_sym

        self.class.send(:define_method, attr_sym) do |*args|
          if args.count > 0
            self[attr].where(*args)
          else
            self[attr]
          end
        end

        ## Don't stomp on _resource's methods
        unless _resource.respond_to?(attr_sym)
          _resource.class.send(:define_method, attr_sym) do |*args|
            links.send(attr_sym, *args)
          end
        end
      end
    end

    def []=(attr, value) # :nodoc:
      super(attr.to_s, value)
    end

    def [](key) # :nodoc:
      return super(key.to_s) if self.has_key?(key.to_s)
      return super(key.to_sym) if self.has_key?(key.to_sym)
      nil
    end

    def method_missing(method, *args) # :nodoc:
      return self[method] if self[method]
      raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
    end

  end
end

