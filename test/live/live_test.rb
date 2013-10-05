require 'test_helper'
require 'rack'
require 'json'
require File.expand_path('../live_test_server.rb', __FILE__)


describe HyperResource do
  class WhateverAPI < HyperResource; end

  if RUBY_VERSION[0..2] == '1.8'
    it 'does not run live tests on 1.8' do
      puts "Live tests don't run on Ruby 1.8, skipping."
    end
  else

    before do
      @port = ENV['HR_TEST_PORT'] || (20000 + rand(10000))

      @server_thread = Thread.new do
        Rack::Handler::WEBrick.run(LiveTestServer.new,
                                   :Port => @port,
                                   :AccessLog => [],
                                   :Logger => WEBrick::Log::new("/dev/null", 7))
      end

      @api = WhateverAPI.new(:root => "http://localhost:#{@port}/")

      @api.get rescue sleep(0.2) and retry  # block until server is ready
    end

    after do
      @server_thread.kill
    end

    describe 'live tests' do
      it 'works at all' do
        root = @api.get
        root.wont_be_nil
        root.name.must_equal 'whatever API'
        root.must_be_kind_of HyperResource
        root.must_be_instance_of WhateverAPI::Root
      end

      it 'follows links' do
        root = @api.get
        root.links.must_respond_to :widgets
        widgets = root.widgets.get
        widgets.must_be_kind_of HyperResource
        widgets.must_be_instance_of WhateverAPI::WidgetSet
      end

      it 'observes proper classing' do
        root = @api.get
        root.must_be_instance_of WhateverAPI::Root
        root.links.must_be_instance_of WhateverAPI::Root::Links
        root.attributes.must_be_instance_of WhateverAPI::Root::Attributes

        root.widgets.must_be_instance_of WhateverAPI::Root::Link
        #root.widgets.first.class.must_equal 'WhateverAPI::Widget'  ## TODO!
      end

      it 'can update' do
        root = @api.get
        widget = root.widgets.first
        widget.name = "Awesome Widget dood"
        resp = widget.update
        resp.attributes.must_equal widget.attributes
        resp.wont_equal widget
      end

      it 'can create' do
        widget_set = @api.widgets.get
        new_widget = widget_set.create(:name => "Cool Widget brah")
        new_widget.class.to_s.must_equal 'WhateverAPI::Widget'
        new_widget.name.must_equal "Cool Widget brah"
      end

      it 'can delete' do
        root = @api.get
        widget = root.widgets.first
        del = widget.delete
        del.class.to_s.must_equal 'WhateverAPI::Message'
        del.message.must_equal "Deleted widget."
      end

    end # describe 'live tests'

  end # if
end # describe HyperResource

