require 'test_helper'

stub_connection = Faraday.new do |builder|
  builder.adapter :test do |stub|
    stub.get('/') {[ 200, {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Root'},
      <<-EOT
{ "name":"Stub API",
  "_links": {
    "self": {"href": "/"},
    "dummies": {"href": "/dummies{?email,name}", "templated": true}
  }
}
      EOT
    ]}

    joe_dummy = <<-EOT
{ "first_name": "Joe", "last_name": "Dummy",
  "_links": {
    "self": {"href": "/dummies/1"},
    "root": {"href": "/"}
  }
}
    EOT

    stub.get('/dummies')   {[ 200, {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Dummies'},
      <<-EOT
{ "_embedded": { "dummies": [ #{joe_dummy} ] },
  "_links": {
    "self": {"href": "/dummies"},
    "root": {"href": "/"}
  }
}
      EOT
    ]}

    stub.post('/dummies') {[
      201,
      { 'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Dummies',
        'Location' => '/dummies/1'},
      joe_dummy
    ]}

    stub.get('/dummies/1') {[
      200,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Dummy'},
      joe_dummy
    ]}

    stub.put('/dummies/1') {[
      200,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Dummy'},
      joe_dummy
    ]}

    stub.patch('/dummies/1') {[
      200,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Dummy'},
      joe_dummy
    ]}

    stub.delete('/dummies/1') {[
      200,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json'},
      ''
    ]}

    # from Rack specs 'Content-type' => 'application/vnd.dummy.v1+hal+json'
    stub.get('/204_with_nil_body') {[
        204,
        {},
        nil
    ]}
    stub.get('/204_with_empty_string_body') {[
        204,
        {},
        ''
    ]}

    stub.get('/204_with_empty_hash_body') {[
        204,
        {},
        {}
    ]}


    stub.get('/404') {[
      404,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Error'},
      '{"error": "Not found", "_links": {"root":{"href":"/"}}}'
    ]}

    stub.get('/500') {[
      500,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Error'},
      '{"error": "Internal server error", "_links": {"root":{"href":"/"}}}'
    ]}

    stub.get('/garbage') {[
      200,
      {'Content-type' => 'application/json'},
      '!@#$%!@##%$!@#$%^  (This is very invalid JSON)'
    ]}
  end
end

describe HyperResource::Modules::HTTP do
  class DummyAPI < HyperResource
    class Link < HyperResource::Link
    end
  end

  before do
    DummyAPI::Link.any_instance.stubs(:faraday_connection).returns(stub_connection)
  end

  describe 'GET' do
    it 'works at a basic level' do
      hr = DummyAPI.new(:root => 'http://example.com/')
      root = hr.get
      root.wont_be_nil
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI::Root
      root.links.must_be_instance_of DummyAPI::Root::Links
      assert root.links.dummies
    end

    it 'raises client error' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => '404')
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ClientError => e
        e.response.wont_be_nil
      end
    end

    it 'Accepts response without a body (example status 204 with nil body)' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => '204_with_nil_body')
      root = hr.get
      root.wont_be_nil
      root.links.must_be_empty
      root.attributes.must_be_empty
      root.objects.must_be_empty
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI

      root.response.status.must_equal 204
      root.response.body.must_be_nil
    end

    it 'Accepts response without a body (example status 204 with empty string body)' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => '204_with_empty_string_body')
      root = hr.get
      root.wont_be_nil
      root.links.must_be_empty
      root.attributes.must_be_empty
      root.objects.must_be_empty
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI

      root.response.status.must_equal 204
      root.response.body.must_equal('')
    end

    it 'Accepts response without a body (example status 204 with empty hash body)' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => '204_with_empty_hash_body')
      root = hr.get
      root.wont_be_nil
      root.links.must_be_empty
      root.attributes.must_be_empty
      root.objects.must_be_empty
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI

      root.response.status.must_equal 204
      root.response.body.must_equal({})
    end

    it 'raises server error' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => '500')
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ServerError => e
        e.response.wont_be_nil
      end
    end

    it 'raises response error' do
      hr = DummyAPI.new(:root => 'http://example.com/', :href => 'garbage')
      begin
        hr.get
        assert false # shouldn't get here
      rescue HyperResource::ResponseError => e
        e.response.wont_be_nil
        e.cause.must_be_kind_of Exception
      end
    end

    it 'does get_response' do
      hr = DummyAPI.new(:root => 'http://example.com/')
      root = hr.get_response
      root.wont_be_nil
      root.must_be_kind_of Faraday::Response
    end
  end
end
