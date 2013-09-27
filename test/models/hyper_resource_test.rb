require 'test_helper'

describe HyperResource do
  before do
    @rsrc = HyperResource.new
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  it "uses method_missing on :attr methods" do
    @rsrc.attr1.must_equal 'val1'
    @rsrc.attr2.must_equal 'val2'
  end

  it 'uses method_missing on :attr= methods' do
    @rsrc.attr1 = :foo
    @rsrc.attr1.must_equal :foo
  end
end

