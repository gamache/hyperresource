class HyperResource
  class Attributes < Hash

    attr_accessor :_resource # @private

    def initialize(resource=nil) # @private
      self._resource = resource || HyperResource.new
    end

    ## Returns +true+ if the given attribute has been changed since creation
    ## time, +false+ otherwise.
    ## If no attribute is given, return whether any attributes have been
    ## changed.
    def changed?(attr=nil)
      @_hr_changed ||= Hash.new(false)
      return @_hr_changed[attr.to_sym] if attr
      return @_hr_changed.keys.count > 0
    end

    ## Returns a hash of the attributes and values which have been changed
    ## since creation time.
    def changed_attributes
      @_hr_changed.select{|k,v| v}.keys.inject({}) {|h,k| h[k]=self[k]; h}
    end

    def []=(attr, value) # @private
      return self[attr] if self[attr] == value
      _hr_mark_changed(attr) 
      super(attr.to_s, value)
    end

    def [](key) # @private
      return super(key.to_s) if self.has_key?(key.to_s)
      return super(key.to_sym) if self.has_key?(key.to_sym)
      nil
    end

    def method_missing(method, *args) # @private
      method = method.to_s
      if self[method]
        self[method]
      elsif method[-1,1] == '='
        self[method[0..-2]] = args.first
      else
        raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
      end
    end

    def respond_to?(method, *args) # @private
      method = method.to_s
      return true if self.has_key?(method)
      return true if method[-1,1] == '=' && self.has_key?(method[0..-2])
      super
    end

    def _hr_clear_changed # @private
      @_hr_changed = nil
    end

    def _hr_mark_changed(attr, is_changed=true) # @private
      attr = attr.to_sym
      @_hr_changed ||= Hash.new(false)
      @_hr_changed[attr] = is_changed
    end

  end
end

