class HyperResource::Attributes < Hash
  # Initialize attributes from a HAL response.
  def init_from_hal(hal_resp)
    (hal_resp.keys - ['_links', '_embedded']).map(&:to_s).each do |attr|
      self[attr] = hal_resp[attr]
      define_singleton_method(attr.to_sym)       {    self[attr]  }
      define_singleton_method("#{attr}=".to_sym) {|v| self[attr]=v}
    end
  end
end
