require 'test_helper'
__END__
describe HyperResource::Attributes do

  describe 'accessors' do
    before do
      @attribs = HyperResource::Attributes.new
      @attribs.response_body = HAL_BODY
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

end
