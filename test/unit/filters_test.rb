require 'test_helper'

describe 'HyperResource#incoming_body_filter' do
  class IncomingBodyFilterAPI < HyperResource
    def incoming_body_filter(hash)
      super(Hash[ hash.map{|(k,v)| ["awesome_#{k}", "awesomer #{v}"]} ])
    end
  end

  before do
    @rsrc = IncomingBodyFilterAPI.new(:root => 'http://example.com')
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  it 'filters incoming attributes' do
    assert_raises NoMethodError do
      @rsrc.attr1
    end
    @rsrc.awesome_attr1.must_equal 'awesomer val1'
  end
end

describe 'HyperResource#outgoing_uri_filter' do
  class OutgoingUriFilterAPI < HyperResource
    def outgoing_uri_filter(hash)
      super(Hash[
        hash.map do |(k,v)|
          if k=='foobar'
            [k, "OMGOMG_#{v}"]
          else
            [k,v]
          end
        end
      ])
    end
  end

  before do
    @rsrc = OutgoingUriFilterAPI.new(:root => 'http://example.com')
    @rsrc.adapter.apply(HAL_BODY, @rsrc)
  end

  it 'filters outgoing uri params' do
    foobar_link = @rsrc.links.foobars.first
    foobar_link.must_be_instance_of OutgoingUriFilterAPI::Link
    link_with_params = foobar_link.where(:foobar => "test")
    link_with_params.href.must_equal "http://example.com/foobars/OMGOMG_test"
  end

end
