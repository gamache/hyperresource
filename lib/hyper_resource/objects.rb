class HyperResource::Objects < Hash
  attr_accessor :parent_resource
  def initialize(parent_resource=nil)
    self.parent_resource = parent_resource || HyperResource.new
  end
  def init_from_hal(hal_resp)
    return unless hal_resp['_embedded']
    hal_resp['_embedded'].each do |name, collection|
      self[name] = collection.map do |obj|
        self.parent_resource.new_from_hal(obj)
      end
      unless self.respond_to?(name.to_sym)
        define_singleton_method(name.to_sym) { self[name] }
      end
      unless self.parent_resource.respond_to?(name.to_sym)
        self.parent_resource.define_singleton_method(name.to_sym) {self[name]}
      end
    end
  end

  ## Returns the first item in the first collection in +self+.
  alias_method :first_orig, :first
  def first
    self.first_orig[1][0]
  end

  ## Returns the ith item in the first collection in +self+.
  def [](i)
    self.first_orig[1][i]
  end
end
