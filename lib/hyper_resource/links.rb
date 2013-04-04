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
        define_singleton_method(rel.to_sym) { self[rel] }
      end
    end

  end
end


