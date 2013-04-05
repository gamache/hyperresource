class HyperResource::Objects < Hash
  attr_accessor :parent_resource
  def initialize(parent_resource=nil)
    self.parent_resource = parent_resource || HyperResource.new
  end
  def init_from_hal(hal_resp)
    return unless hal_resp['_embedded']
    hal_resp['_embedded'].each do |name, collection|
      self[name] = collection.map do |obj|
        self.parent_resource.new_from_hal_response(obj)
      end
      unless self.respond_to?(name.to_sym)
        define_singleton_method(name.to_sym) { self[name] }
      end
      unless self.parent_resource.respond_to?(name.to_sym)
        self.parent_resource.define_singleton_method(name.to_sym) {self[name]}
      end
    end
  end
end
