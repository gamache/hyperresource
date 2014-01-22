class HyperResource
  class Links < Hash
    attr_accessor :_resource

    def initialize(resource=nil)
     self._resource = resource || HyperResource.new
    end

    ## []= is patched to recognize and use abbreviations of link rels,
    ## as well as the original names.  This is performed here rather than
    ## in [] for efficiency; you read more than you write.
    def []=(attr, value) # @private
      attr = attr.to_s

      ## Every link must appear under its proper name.
      names = [attr]

      ## Extract 'foo' from e.g. 'http://example.com/foo',
      ## 'http://example.com/url#foo', 'somecurie:foo'.
      if m=attr.match(%r{[:/#](.+)})
        names << m[1]
      end

      ## Underscore all non-word characters.
      underscored_names = names.map{|n| n.gsub(/[^a-zA-Z_]/, '_')}
      names = (names + underscored_names).uniq

      ## Register this link under every name we've come up with.
      names.each do |name|
        super(name, value)
      end
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

