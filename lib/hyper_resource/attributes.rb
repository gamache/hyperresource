class HyperResource
  class Attributes < Hash

    attr_accessor :_resource # @private

    def initialize(resource=nil) # @private
      self._resource = resource || HyperResource.new
    end

    ## Creates accessor methods in self.class and self._resource.class.
    ## Protects against method creation into HyperResource::Attributes and
    ## HyperResource classes.  Just subclasses, please!
    def _hr_create_methods!(opts={}) # @private
      return if self.class.to_s == 'HyperResource::Attributes'
      return if self._resource.class.to_s == 'HyperResource'
      return if self.class.send(
        :class_variable_defined?, :@@_hr_created_attributes_methods)

      self.keys.each do |attr|
        attr_sym = attr.to_sym
        attr_eq_sym = "#{attr}=".to_sym

        self.class.send(:define_method, attr_sym) do
          self[attr]
        end
        self.class.send(:define_method, attr_eq_sym) do |val|
          self[attr] = val
        end

        ## Don't stomp on _resource's methods
        unless _resource.respond_to?(attr_sym)
          _resource.class.send(:define_method, attr_sym) do
            attributes.send(attr_sym)
          end
        end
        unless _resource.respond_to?(attr_eq_sym)
          _resource.class.send(:define_method, attr_eq_sym) do |val|
            attributes.send(attr_eq_sym, val)
          end
        end
      end

      ## This is a good time to mark this object as not-changed
      _hr_clear_changed

      self.class.send(:class_variable_set, :@@_hr_created_attributes_methods, true) 
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
      return self[attr] if self.has_key?(attr.to_s) && self[attr] == value
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
      if has_key?(method)
        self[method]
      elsif method[-1,1] == '='
        self[method[0..-2]] = args.first
      else
        raise NoMethodError, "undefined method `#{method}' for #{self.inspect}"
      end
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

