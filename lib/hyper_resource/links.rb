class HyperResource
 class Links < Hash
   attr_accessor :resource

   def initialize(resource=nil)
     self.resource = resource || HyperResource.new
   end

    # Initialize links from a HAL response.
    def init_from_hal(hal_resp)
      return unless hal_resp['_links']
      hal_resp['_links'].each do |rel, link_spec|
        self[rel] = HyperResource::Link.new(resource, link_spec)
        unless self.respond_to?(rel.to_sym)
          define_singleton_method(rel.to_sym) { self[rel] }
        end
        unless self.resource.respond_to?(rel.to_sym)
          self.resource.define_singleton_method(rel.to_sym) {self.links[rel]}
        end
      end
    end

  end
end


