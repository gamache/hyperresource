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

        self.class.send(:define_method, attr_sym) do
          self[attr]
        end

        ## Don't stomp on _resource's methods
        unless _resource.respond_to?(attr_sym)
          _resource.class.send(:define_method, attr_sym) do
            links.send(attr_sym)
          end
        end
      end
    end

  end
end

