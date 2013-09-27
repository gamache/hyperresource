require 'test_helper'

describe HyperResource::Attributes do
  class TestAPI < HyperResource; end

  describe 'accessors' do
    before do
      @rsrc = TestAPI.new
      @rsrc.adapter.apply(HAL_BODY, @rsrc)
      @attribs = @rsrc.attributes
    end

    it "creates accessors for all attributes" do
      @attribs.must_respond_to :attr1
      @attribs.attr1.must_equal 'val1'

      @attribs.must_respond_to :attr2
      @attribs.attr2.must_equal 'val2'
    end

    it 'leaves _links and _embedded alone' do
      @attribs.wont_respond_to :_links
      @attribs.wont_respond_to :_embedded
    end

    it 'allows values to be changed' do
      @attribs.attr1 = :foo
      @attribs.attr1.must_equal :foo
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
