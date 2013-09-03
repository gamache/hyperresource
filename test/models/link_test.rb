require 'test_helper'

describe HyperResource::Link do
  before do
    @link = HyperResource::Link.new(nil, {'href' => '/foo{?blarg}',
                                          'name' => 'foo',
                                          'templated' => true})
  end

  describe '#where' do
    it 'where does not mutate original link' do
      link2 = @link.where('blarg' => 22)
      @link.params['blarg'].must_be_nil
      link2.params['blarg'].must_equal 22
    end
  end

  describe '#href' do
    it 'href fills in URI template params' do
      link2 = @link.where('blarg' => 22)
      link2.href.must_equal '/foo?blarg=22'
    end
  end

  describe '#name' do
    it 'comes from the link spec' do
      @link.name.must_equal 'foo'
    end

    it 'is kept when using where' do
      link2 = @link.where('blarg' => 42)
      link2.name.must_equal 'foo'
    end
  end

  describe '#resource' do
    it 'resource creates a new HyperResource instance' do
      @link.resource.must_be_instance_of HyperResource
    end

    it 'returned resource has not been loaded yet' do
      @link.resource.response.must_be_nil
    end
  end
end
