require 'test_helper'

describe HyperResource do
  class NoMethodsAPI < HyperResource; end

  before do
    @api = NoMethodsAPI.new
    @api.adapter.apply(HAL_BODY, @api)
  end

  describe 'respond_to' do
    it "doesn't create methods" do
      @api.methods.wont_include(:attr1)
      @api.attributes.methods.wont_include(:attr1)
      @api.methods.wont_include(:obj1s)
      @api.objects.methods.wont_include(:obj1s)
      @api.methods.wont_include(:foobars)
      @api.links.methods.wont_include(:foobars)
    end

    it "responds_to the right things" do
      @api.must_respond_to(:attr1)
      @api.attributes.must_respond_to(:attr1)
      @api.must_respond_to(:obj1s)
      @api.objects.must_respond_to(:obj1s)
      @api.must_respond_to(:foobars)
      @api.links.must_respond_to(:foobars)
    end
  end
end
