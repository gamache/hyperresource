require 'test_helper'
require 'pry-debugger'

describe 'HyperResource caching' do
  class TestAPI < HyperResource; end

  before do
    @rsrc = TestAPI.new(:root => 'http://example.com')
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  it 'can be dumped with Marshal.dump' do
    dump = Marshal.dump(@rsrc)
    new_rsrc = Marshal.load(dump)
    assert new_rsrc.attr1
  end
end
