require 'test_helper'

describe HyperResource::Links do
  before do
    @links = HyperResource::Links.new
    @links.init_from_hal(HAL_BODY)
  end

  describe '#init_from_hal' do
    it 'creates readers for all links' do
      @links.must_respond_to :self
    end

    it 'creates all links as HyperResource::Link or subclass' do
      @links.self.must_be_kind_of HyperResource::Link
    end
  end

  describe 'implicit .where' do
    it 'link accessor calls .where when called with args' do
      link = @links.self(:blarg => 1)
      link.must_be_kind_of HyperResource::Link
      link.params[:blarg].must_equal 1
    end
  end
end
