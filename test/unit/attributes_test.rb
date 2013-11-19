require 'test_helper'

describe HyperResource::Attributes do
  class TestAPI < HyperResource; end

  describe 'accessors' do
    before do
      @rsrc = TestAPI.new
      @rsrc.adapter.apply(HAL_BODY, @rsrc)
      @attrs = @rsrc.attributes
    end

    it "provides access to all attributes" do
      @attrs.attr1.must_equal 'val1'
      @attrs.attr2.must_equal 'val2'
    end

    it 'leaves _links and _embedded alone' do
      assert_raises NoMethodError do
        @attrs._links
      end
      assert_raises NoMethodError do
        @attrs._embedded
      end
    end

    it 'allows values to be changed' do
      @attrs.attr1 = :foo
      @attrs.attr1.must_equal :foo
    end
  end

  describe 'changed' do
    before do
      @rsrc = TestAPI.new
      @rsrc.adapter.apply(HAL_BODY, @rsrc)
    end

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
