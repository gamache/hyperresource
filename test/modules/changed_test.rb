require 'test_helper'

describe HyperResource do
  before do
    @rsrc = HyperResource.new.new_from_hal(HAL_BODY)
  end
  describe 'changed' do
    it 'marks attributes as changed' do
      @rsrc.changed?(:attr1).must_equal false
      @rsrc.changed?.must_equal false
      @rsrc.attr1 = :wowie_zowie
      @rsrc.changed?(:attr1).must_equal true
      @rsrc.changed?(:attr2).must_equal false
      @rsrc.changed?.must_equal true
    end
  end
end
