require 'test_helper'

describe "Embedded Resources" do
  class TestAPI < HyperResource; end

  it 'supports an array of embedded resources' do
    hyper = TestAPI.new
    hyper.objects.class.to_s.must_equal 'TestAPI::Objects'
    hyper.adapter.apply({"_embedded" => {"foo" => [{"_links" => {"self" => {"href" => "http://example.com/"}}}]}},
                        hyper)
    hyper.foo.must_be_instance_of Array
    hyper.foo.first.href.must_equal 'http://example.com/'
  end

  it 'supports a single embedded resource' do
    hyper = HyperResource.new(namespace: 'TestAPI')
    hyper.adapter.apply({"_embedded" => {"foo" => {"_links" => {"self" => {"href" => "http://example.com/"}}}}},
                        hyper)
    hyper.foo.href.must_equal 'http://example.com/'
  end
end
