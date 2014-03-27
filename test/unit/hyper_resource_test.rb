require 'test_helper'

describe HyperResource do
  before do
    @rsrc = HyperResource.new(:root => 'http://example.com', :href => '/obj1/')
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  describe 'method_missing' do
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

  describe 'Enumerable support' do
    it 'implements each' do
      vals = []
      @rsrc.each {|r| vals << r.attr3}
      vals.must_equal ['val3', 'val5']
    end

    it 'supports []' do
      @rsrc.first.must_equal @rsrc[0]
    end

    it 'supports map' do
      @rsrc.map(&:attr3).must_equal ['val3', 'val5']
    end
  end

  describe '#to_link' do
    it 'converts into a link' do
      link = @rsrc.to_link
      link.href.must_equal @rsrc.href
    end
  end

end

