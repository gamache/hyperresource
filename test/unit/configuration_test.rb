require 'test_helper'


describe HyperResource::Configuration do

  describe '#get and #set' do
    it 'works' do
      cfg = HyperResource::Configuration.new
      cfg.set('test', 'a', 'b')
      cfg.get('test', 'a').must_equal 'b'
      cfg.get('test2', 'a').must_be_nil
      cfg.get('test', 'b').must_be_nil
    end
  end

  describe '#clone' do
    it 'works' do
      cfg = HyperResource::Configuration.new
      b = 'b'
      cfg.set('test', 'a', b)
      newcfg = cfg.clone

      newcfg.get('test', 'a').must_equal 'b'

      ## No shared structure at first level
      newcfg.set('test', 'a', 'c')
      cfg.get('test', 'a').must_equal 'b'
    end
  end

  describe '#get_for_url' do
    it 'returns exact matches' do
      cfg = HyperResource::Configuration.new
      cfg.set('example.com', 'a', 'b')

      cfg.get_for_url('http://example.com', 'a').must_equal 'b'
      cfg.get_for_url('https://example.com/v1/omg', 'a').must_equal 'b'
      cfg.get_for_url('http://example.com?utm_source=friendster', 'a').must_equal 'b'
      cfg.get_for_url('http://example.com', 'a').must_equal 'b'

      cfg.get_for_url('http://example2.com', 'a').must_be_nil
      cfg.get_for_url('http://www.example.com', 'a').must_be_nil
      cfg.get_for_url('http://example.com.au', 'a').must_be_nil
    end

    it 'returns subdomain wildcard matches' do
      cfg = HyperResource::Configuration.new
      cfg.set('*.example.com', 'a', 'b')

      cfg.get_for_url('http://www.example.com', 'a').must_equal 'b'
      cfg.get_for_url('https://www.example.com/INDEX.HTM', 'a').must_equal 'b'
      cfg.get_for_url('http://www4.us.example.com', 'a').must_equal 'b'

      cfg.get_for_url('http://example.com', 'a').must_be_nil
    end
  end

  describe '#set_for_url' do
    it 'works' do
      cfg = HyperResource::Configuration.new
      cfg.set_for_url('http://example.com', 'a', 'b')
      cfg.get('example.com', 'a').must_equal 'b'
      cfg.get_for_url('http://example.com', 'a').must_equal 'b'
    end
  end

  describe '#get_possible_masks_for_host' do
    it 'generates correct hostmasks' do
      cfg = HyperResource::Configuration.new
      masks = cfg.send(:get_possible_masks_for_host, 'www4.us.example.com')
      masks.must_equal ["www4.us.example.com", "*.us.example.com",
                        "*.example.com", "*.com", "*"]
    end
  end

  describe '#matching_masks_for_url' do
    it 'returns existing hostmasks' do
      cfg = HyperResource::Configuration.new
      cfg.set('www4.us.example.com', 'a', 'b')
      cfg.set('*.example.com', 'a', 'b')
      cfg.set('*', 'a', 'b')
      masks = cfg.send(:matching_masks_for_url, 'http://www4.us.example.com')
      masks.must_equal ["www4.us.example.com", "*.example.com", "*"]
    end
  end

  describe '#subconfig_for_url' do
    it 'merges hostmask configs correctly' do
      cfg = HyperResource::Configuration.new
      cfg.set('www4.us.example.com', 'a', 'b')
      cfg.set('*.example.com', 'd', 'e')
      cfg.set('*', 'a', 'c')

      subconfig = cfg.send(:subconfig_for_url, 'http://www4.us.example.com')
      subconfig['a'].must_equal 'b'
      subconfig['d'].must_equal 'e'
    end
  end

end

