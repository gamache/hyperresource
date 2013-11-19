require 'test_helper'

describe HyperResource::Links do
  class TestAPI < HyperResource; end

  before do
    @rsrc = TestAPI.new
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
    @links = @rsrc.links
  end

  describe '#init_from_hal' do
    it 'provides readers for all links, including CURIE names' do
      assert @links.self
      assert @links.foobars
      assert @links.send('foo:foobars')
    end

    it 'creates reader hash keys for all links, including CURIE names' do
      @links['self'].wont_be_nil
      @links['foobars'].wont_be_nil
      @links['foo:foobars'].wont_be_nil
    end

    it 'creates all links as HyperResource::Link or subclass' do
      @links.self.must_be_kind_of HyperResource::Link
    end

    it 'handles link arrays' do
      @links.foobars.must_be_kind_of Array
      @links.send(:'foo:foobars').must_be_kind_of Array
      @links.foobars.first.must_be_kind_of HyperResource::Link
    end
  end

  describe 'implicit .where' do
    it 'link accessor calls .where when called with args' do
      link = @links.self(:blarg => 1)
      link.must_be_kind_of HyperResource::Link
      link.params['blarg'].must_equal 1
    end
  end
end
