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

    stub.get('/404') {[
      404,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Error'},
      '{"error": "Not found", "_links": {"root":"/"}}'
    ]}

    stub.get('/500') {[
      500,
      {'Content-type' => 'application/vnd.dummy.v1+hal+json;type=Error'},
      '{"error": "Internal server error", "_links": {"root":"/"}}'
    ]}
  end
end

describe HyperResource::Modules::HTTP do
  class DummyAPI < HyperResource; end

  before do
    DummyAPI.any_instance.stubs(:faraday_connection).returns(stub_connection)
  end

  describe 'GET' do
    it 'works at a basic level' do
      hr = DummyAPI.new(root: '/')
      root = hr.get
      root.wont_be_nil
      root.must_be_kind_of HyperResource
      root.must_be_instance_of DummyAPI::Root
      root.links.must_be_instance_of DummyAPI::Root::Links
      root.links.must_respond_to :dummies
    end

    it 'raises client error' do
      hr = DummyAPI.new(root: '/', href: '404')
      assert_raises HyperResource::ClientError do
        hr.get
      end
    end

    it 'raises server error' do
      hr = DummyAPI.new(root: '/', href: '500')
      assert_raises HyperResource::ServerError do
        hr.get
      end
    end
  end
end
