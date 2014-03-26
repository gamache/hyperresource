require 'uri_template'
require 'weakref'

class HyperResource

  ## HyperResource::Link is an object to represent a hyperlink and its
  ## URL or body parameters.  It automates loading of the resource
  ## it points to: `method_missing` loads a resource, then repeats the
  ## method call on it.
  class Link

    attr_accessor :base_href,
                  :name,
                  :templated,
                  :params,
                  :default_method

    ## This is a WeakRef so that HyperResource objects don't leak.
    attr_accessor :resource # @private

    ## Returns true if this link is templated.
    def templated?; templated end

    ## +link_spec+ must have +href+ and +name+ defined
    def initialize(resource, link_spec={})
      self.resource = resource.is_a?(WeakRef) ? resource : WeakRef.new(resource)
      self.base_href = link_spec['href']
      self.name = link_spec['name']
      self.templated = !!link_spec['templated']
      self.params = link_spec['params'] || {}
      self.default_method = link_spec['method'] || 'get'
    end

    ## Returns this link's href, applying any URI template params.
    def href
      if self.templated?
        filtered_params = self.resource.outgoing_uri_filter(params)
        URITemplate.new(self.base_href).expand(filtered_params)
      else
        self.base_href
      end
    end

    ## Returns a new scope with the given params; that is, returns a copy of
    ## itself with the given params applied.
    def where(params)
      params = Hash[ params.map{|(k,v)| [k.to_s, v]} ]
      self.class.new(self.resource,
                     'href' => self.base_href,
                     'name' => self.name,
                     'templated' => self.templated,
                     'params' => self.params.merge(params),
                     'method' => self.default_method)
    end

    ## Returns a HyperResource representing this link.
    def make_resource
      puts "\n\n*** make_resource ***"
      #pp resource
      puts resource.namespace.inspect
      puts " erp"
      v =resource.new_resource_with_href(self.href)
      puts "*********************\n\n"
      v
    end

    ## Delegate HTTP methods to resource.
    def get(*args);    self.make_resource.get(*args)    end
    def post(*args);   self.make_resource.post(*args)   end
    def patch(*args);  self.make_resource.patch(*args)  end
    def put(*args);    self.make_resource.put(*args)    end
    def delete(*args); self.make_resource.delete(*args) end

    ## If we were called with a method we don't know, load this resource
    ## and pass the message along.  This achieves implicit loading.
    def method_missing(method, *args)
      self.send(default_method || :get).send(method, *args)
    end

  end
end

