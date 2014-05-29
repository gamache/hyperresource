require 'test_helper'

describe HyperResource do
  describe '#config' do
    it 'inherits different masks' do
      res1 = HyperResource.new(:root => 'http://example.com')
      res1.config('res1' => {'test1' => 123,
                             'test2' => 123})

      link = HyperResource::Link.new(res1, :href => '/')
      res2 = HyperResource.new_from(:link => link,
                                    :resource => res1,
                                    :body => {})
      res2.config('res2' => {'test2' => 234})

      res2.config.get('res2', 'test2').must_equal 234
      res2.config.get('res1', 'test1').must_equal 123
    end

    it 'merges the config attribute hashes on the same mask, non-hash values' do
      res1 = HyperResource.new(:root => 'http://example.com')
      res1.config('res1' => {'test1' => 123,
                             'test2' => 123})

      link = HyperResource::Link.new(res1, :href => '/')
      res2 = HyperResource.new_from(:link => link,
                                    :resource => res1,
                                    :body => {})
      res2.config('res1' => {'test2' => 234})

      res2.config.get('res1', 'test2').must_equal 234
      res2.config.get('res1', 'test1').must_equal 123
    end

    it 'merges the config attribute hashes on the same mask, hash values' do
      res1 = HyperResource.new(:root => 'http://example.com')
      res1.config('res1' => {'test1' => {'a' => 'b', 'c' => 'd'}})

      link = HyperResource::Link.new(res1, :href => '/')
      res2 = HyperResource.new_from(:link => link,
                                    :resource => res1,
                                    :body => {})
      res2.config('res1' => {'test1' => {'a' => 'test'}})

      res2.config.get('res1', 'test1')['a'].must_equal 'test'
      res2.config.get('res1', 'test1')['c'].must_equal 'd'
    end

  end
end

