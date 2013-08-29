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
        if link_spec.is_a? Array
          self[rel] = link_spec.map do |link|
            new_link_from_spec(link)
          end
        else
          self[rel] = new_link_from_spec(link_spec)
        end
        create_methods_for_link_rel(rel) unless self.respond_to?(rel.to_sym)
      end
    end

  protected

    def new_link_from_spec(link_spec) # :nodoc:
      HyperResource::Link.new(resource, link_spec)
    end

    def create_methods_for_link_rel(rel) # :nodoc:
      link = self[rel]
      define_singleton_method(rel.to_sym) do |*args|
        return link if args.empty?
        link.where(*args)
      end
    end

  end
end


