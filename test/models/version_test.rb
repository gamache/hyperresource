require './test/minitest_helper'

describe HyperResource::VERSION do
  it 'should be above zero' do
    Gem::Version.new(HyperResource::VERSION).must_be :>,
      Gem::Version.new('0')
  end
end
