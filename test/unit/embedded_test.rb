require 'test_helper'

describe "Embedded Resources" do
  class TestAPI < HyperResource; self.root = 'http://example.com' end

  it 'supports an array of embedded resources' do
    hyper = TestAPI.new
    hyper.objects.class.to_s.must_equal 'TestAPI::Objects'
    body = { "_embedded" => {
               "foo" => [
                 {"_links" => {"self" => {"href" => "http://example.com/"}}}
               ]
             }
           }
    hyper.adapter.apply(body, hyper)
    hyper.foo.must_be_instance_of Array
    hyper.foo.first.href.must_equal 'http://example.com/'
  end

  it 'supports a single embedded resource' do
    hyper = TestAPI.new
    body = { "_embedded" => {
               "foo" =>
                 {"_links" => {"self" => {"href" => "http://example.com/"}}}
             }
           }
    hyper.adapter.apply(body, hyper)
    hyper.foo.href.must_equal 'http://example.com/'
  end
end
