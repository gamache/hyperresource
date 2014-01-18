class HyperResource
  class Links < Hash
    attr_accessor :_resource

    def initialize(resource=nil)
     self._resource = resource || HyperResource.new
    end

    def []=(attr, value) # @private
      super(attr.to_s, value)
    end

    def [](key) # @private
      return super(key.to_s) if self.has_key?(key.to_s)
      return super(key.to_sym) if self.has_key?(key.to_sym)
      nil
    end

    def method_missing(method, *args) # @private
      unless self[method]
        raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
      end

      if args.count > 0
        self[method].where(*args)
      else
        self[method]
      end
    end

    def respond_to?(method, *args) # @private
      method = method.to_s
      return true if self.has_key?(method)
      super
    end
  end
end

