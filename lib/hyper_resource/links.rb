require 'weakref'

class HyperResource

  ## HyperResource::Links is a modified Hash that permits lookup
  ## of a link by its link relation (rel), or an abbreviation thereof.
  ## It also provides read access through `method_missing`.
  ##
  ## For example, a link with rel `someapi:widgets` is accessible
  ## by any of `self.widgets`, `self['widgets']`, `self[:widgets]`, and
  ## `self['someapi:widgets'].
  class Links < Hash

    ## This is a WeakRef so that HyperResource objects don't leak.
    attr_accessor :resource # @private

    def initialize(resource=nil) # @private
      self.resource = WeakRef.new(resource) if resource
    end

    ## Stores a link for future retrieval by its link rel or abbreviations
    ## thereof.
    def []=(rel, link)
      rel = rel.to_s

      ## Every link must appear under its literal name.
      names = [rel]

      ## Extract 'foo' from e.g. 'http://example.com/foo',
      ## 'http://example.com/url#foo', 'somecurie:foo'.
      if m=rel.match(%r{[:/#](.+)})
        names << m[1]
      end

      ## Underscore all non-word characters.
      underscored_names = names.map{|n| n.gsub(/[^a-zA-Z_]/, '_')}
      names = (names + underscored_names).uniq

      ## Register this link under every name we've come up with.
      names.each do |name|
        super(name, link)
      end
    end

    ## Retrieves a link by its rel.
    def [](rel)
      super(rel.to_s)
    end

    ## Provides links.somelink(:a => b) to links.somelink.where(:a => b)
    ## expansion.
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
      return true if self.has_key?(method.to_s)
      super
    end
  end
end

