require 'test_helper'
require 'net/http'

describe HyperResource::Modules::Bless do
  before do
    Kernel.module_eval "class Foo; end"
    resp = Net::HTTPResponse.new(nil, nil, nil)
    resp['content-type'] = 'application/vnd.example+json;type=Foo'
    @hr = HyperResource.new
    @hr.namespace = 'Barf'
    @hr.response = resp
  end

  describe '#data_type_name' do
    it 'detects data type from content-type' do
      @hr.data_type_name.must_equal 'Foo'
    end

    it 'returns nil when unsure of data type' do
      @hr.response = nil
      @hr.data_type_name.must_be_nil
    end
  end

  describe "#resource_class" do
    it 'returns response class when it does not exist yet' do
      rc = @hr.resource_class
      rc.must_be_instance_of Class
      rc.must_equal Barf::Foo
    end

    it 'returns self.class when unsure of data type name' do
      @hr.stubs(:data_type_name).returns(nil)
      @hr.namespace = nil
      @hr.resource_class.must_equal @hr.class
    end

    it "returns class in global namespace when self.namespace==''" do 
      @hr.namespace = ''
      @hr.resource_class.must_equal ::Foo
    end
  end

  describe '#blessed' do
    it 'inheritance works right' do
      bhr = @hr.blessed
      bhr.must_be_instance_of Barf::Foo
      bhr.must_be_kind_of Barf
      bhr.must_be_kind_of HyperResource
    end

    it 'allows extension of an object' do
      class Barf; class Foo; def blarg; 1 end end end # :nodoc
      bhr = @hr.blessed
      bhr.must_respond_to :blarg
      bhr.blarg.must_equal 1
    end
  end

end
