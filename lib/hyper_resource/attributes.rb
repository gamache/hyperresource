class HyperResource::Attributes < Hash
  attr_accessor :parent_resource

  def initialize(resource=nil)
    self.parent_resource = resource || HyperResource.new
  end

  ## Initialize attributes from a HAL response.
  def init_from_hal(hal_resp)
    (hal_resp.keys - ['_links', '_embedded']).map(&:to_s).each do |attr|
      self[attr] = hal_resp[attr]

      attr_sym = attr.to_sym
      attr_eq_sym = "#{attr}=".to_sym

      ## Define rsrc.attributes.foo and rsrc.attributes.foo=
      unless self.respond_to?(attr_sym)
        define_singleton_method(attr_sym) do
          self[attr]
        end
        define_singleton_method(attr_eq_sym) do |v|
          self.parent_resource._hr_mark_changed(attr_sym)
          self[attr] = v
        end
      end

      ## Define rsrc.foo and rsrc.foo=
      unless self.parent_resource.respond_to?(attr_sym)
        self.parent_resource.define_singleton_method(attr_sym) do
          self.attributes.send(attr_sym)
        end
        self.parent_resource.define_singleton_method(attr_eq_sym) do |v|
          self.attributes.send(attr_eq_sym, v)
        end
      end

    end
  end



end
