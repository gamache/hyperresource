require 'test_helper'

describe "Embedded Resources" do
  it 'supports an array of embedded resources' do
    hyper = HyperResource.new
    hyper.response_body = {"_embedded" => {"foo" => [{"_links" => {"self" => {"href" => "http://example.com/"}}}]}}
    hyper.init_from_response_body!
    hyper.foo.must_be_instance_of Array
    hyper.foo.first.href.must_equal 'http://example.com/'
  end

  it 'supports a single embedded resource' do
    hyper = HyperResource.new
    hyper.response_body = {"_embedded" => {"foo" => {"_links" => {"self" => {"href" => "http://example.com/"}}}}}
    hyper.init_from_response_body!
    hyper.foo.href.must_equal 'http://example.com/'
  end
end
