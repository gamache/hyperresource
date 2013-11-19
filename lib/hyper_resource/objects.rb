class HyperResource
  class Objects < Hash
    attr_accessor :_resource

    def initialize(resource=nil) 
      self._resource = resource || HyperResource.new
    end

    ## Creates accessor methods in self.class and self._resource.class.
    ## Protects against method creation into HyperResource::Objects and
    ## HyperResource classes.  Just subclasses, please!
    def _hr_create_methods!(opts={}) # @private
      return if self.class.to_s == 'HyperResource::Objects'
      return if self._resource.class.to_s == 'HyperResource' 
      return if self.class.send(
        :class_variable_defined?, :@@_hr_created_objects_methods) 

      self.keys.each do |attr|
        attr_sym = attr.to_sym

        self.class.send(:define_method, attr_sym) do
          self[attr]
        end

        ## Don't stomp on _resource's methods
        unless _resource.respond_to?(attr_sym)
          _resource.class.send(:define_method, attr_sym) do
            objects.send(attr_sym)
          end
        end
      end

      self.class.send(:class_variable_set, :@@_hr_created_objects_methods, true) 
    end

    def []=(attr, value) # @private
      super(attr.to_s, value)
    end

    ## When +key+ is a string, returns the array of objects under that name.
    ## When +key+ is a number, returns +ith(key)+. Returns nil on lookup
    ## failure.
    def [](key)
      case key
      when String, Symbol
        return super(key.to_s) if self.has_key?(key.to_s)
        return super(key.to_sym) if self.has_key?(key.to_sym)
      when Fixnum
        return ith(key)
      end
      nil
    end

    def method_missing(method, *args) # @private
      return self[method] if self[method]
      raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
    end

  end
end
