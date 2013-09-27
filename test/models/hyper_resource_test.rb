require 'test_helper'

describe HyperResource do
  before do
    @rsrc = HyperResource.new
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  it "uses method_missing on :attr methods" do
    @rsrc.attr1.must_equal 'val1'
    @rsrc.attributes.attr1.must_equal 'val1'
    @rsrc.attr2.must_equal 'val2'
    @rsrc.attributes.attr2.must_equal 'val2'
  end

  it 'uses method_missing on :attr= methods' do
    @rsrc.attr1 = :foo
    @rsrc.attr1.must_equal :foo
  end

  it 'uses method_missing on :link methods' do
    @rsrc.self.must_be_instance_of HyperResource::Link
    @rsrc.links.self.must_be_instance_of HyperResource::Link
  end

  it 'uses method_missing on :obj methods' do
    @rsrc.obj1s.must_be_instance_of Array
    @rsrc.objects.obj1s.must_be_instance_of Array
  end
end

