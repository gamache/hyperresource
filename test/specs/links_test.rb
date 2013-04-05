require 'test_helper'

describe HyperResource::Links do
  describe '#init_from_hal' do
    before do
      @links = HyperResource::Links.new
      @links.init_from_hal(HAL_BODY)
    end

    it 'creates readers for all links' do
      @links.must_respond_to :self
    end

    it 'creates all links as HyperResource::Link' do
      @links.self.must_be_instance_of HyperResource::Link
    end
  end
end
