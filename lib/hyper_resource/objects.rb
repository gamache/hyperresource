class HyperResource
  class Objects < Hash
    attr_accessor :_resource

    def initialize(resource=nil) 
      self._resource = resource || HyperResource.new
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

    def respond_to?(method, *args) # @private
      method = method.to_s
      return true if self.has_key?(method)
      super
    end
  end
end
