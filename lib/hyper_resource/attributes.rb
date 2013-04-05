class HyperResource::Attributes < Hash
  attr_accessor :parent_resource
  def initialize(resource=nil)
    self.parent_resource = resource || HyperResource.new
  end
  # Initialize attributes from a HAL response.
  def init_from_hal(hal_resp)
    (hal_resp.keys - ['_links', '_embedded']).map(&:to_s).each do |attr|
      self[attr] = hal_resp[attr]

      unless self.respond_to?(attr.to_sym)
        define_singleton_method(attr.to_sym)       {    self[attr]  }
        define_singleton_method("#{attr}=".to_sym) {|v| self[attr]=v}
      end

      unless self.parent_resource.respond_to?(attr.to_sym)
        self.parent_resource.define_singleton_method(attr.to_sym) {self[attr]}
        self.parent_resource.define_singleton_method("#{attr}=".to_sym) do |v|
          self[attr] = v
        end
      end
    end
  end
end
