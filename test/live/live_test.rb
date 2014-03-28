require 'test_helper'
require 'rack'
require 'json'
require File.expand_path('../live_test_server.rb', __FILE__)

## Default port 25491 was selected using a meat-based PRNG.
HR_TEST_PORT_1 = ENV['HR_TEST_PORT']   || ENV['HR_TEST_PORT_1'] || 25491
HR_TEST_PORT_2 = ENV['HR_TEST_PORT_2'] || (HR_TEST_PORT_1.to_i + 1)

unless !!ENV['NO_LIVE']

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
          Rack::Handler::WEBrick.run(
            LiveTestServer.new,
            :Port => @port,
            :AccessLog => [],
            :Logger => WEBrick::Log::new("/dev/null", 7)
          )
        end

        @api = make_new_api_resource

        if ENV['DEBUG']
          retries = 5
          begin
            @api.get
          rescue Exception => e
            retries -= 1
            if retries == 0
              puts e
              puts e.message
              puts caller[0..10]
              raise e
            end
            sleep 0.2
            retry
          end
        else
          @api.get rescue sleep(0.2) and retry  # block until server is ready
        end
      end

      after do
        @server_thread.kill
      end

    private

      def make_new_api_resource
        WhateverAPI.new(:root => "http://localhost:#{@port}/")
      end

      def expect_deprecation(rsrc)
        rsrc.class.expects(:_hr_deprecate).returns(true)
      end

    public

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

        it 'loads resources automatically from method_missing' do
          api = make_new_api_resource
          api.widgets.wont_be_nil
        end

        it 'observes proper classing' do
          api = make_new_api_resource
          api.must_be_instance_of WhateverAPI
          root = api.get
          root.must_be_instance_of WhateverAPI::Root
          root.links.must_be_instance_of WhateverAPI::Root::Links
          root.attributes.must_be_instance_of WhateverAPI::Root::Attributes

          root.widgets.must_be_instance_of WhateverAPI::Root::Link
          root.widgets.first.class.to_s.must_equal 'WhateverAPI::Widget'
        end

        it 'can update (DEPRECATED)' do
          root = @api.get
          widget = root.widgets.first
          widget.name = "Awesome Widget dood"
          expect_deprecation(widget)
          resp = widget.update
          resp.attributes.must_equal widget.attributes
          resp.wont_equal widget
        end

        it 'can create (DEPRECATED)' do
          widget_set = @api.widgets.get
          expect_deprecation(widget_set)
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

        it 'can post without implicitly performing a get' do
          link = @api.post_only_widgets
          widget = link.post(:name => 'Cool Widget brah')
          widget.class.to_s.must_equal 'WhateverAPI::PostOnlyWidget'
          widget.name.must_equal "Cool Widget brah"
        end

        it 'passes headers to sub-objects' do
          @api.headers['X-Type'] = 'Foobar'
          root = @api.get
          widget = root.widgets.get.first
          widget.headers['X-Type'].must_equal 'Foobar'
        end

        it 'caches headers separately across instances' do
          api1 = HyperResource.new(
            :root => "http://localhost:#{@port}/conditional_widgets"
          )
          api1.get.type.must_equal 'antiwidget'

          api2 = HyperResource.new(
            :root => "http://localhost:#{@port}/conditional_widgets",
            :headers => { 'WIDGET' => 'true' }
          )
          api2.get.type.must_equal 'widget'
        end

        describe "invocation styles" do
          it 'can use HyperResource with no namespace' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/")
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'HyperResource'
          end

          it 'can use HyperResource with a namespace' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/",
                                    :namespace => 'NsTestApi')
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'NsTestApi::Root'
          end

          class NsExtTestApi < HyperResource
            class Root < NsExtTestApi
              def foo; :foo end
            end
          end
          it 'can use HyperResource with a namespace which is extended' do
            api = HyperResource.new(:root => "http://localhost:#{@port}/",
                                    :namespace => 'NsExtTestApi')
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'NsExtTestApi::Root'
            root.must_respond_to :foo
            root.foo.must_equal :foo
          end


          class SubclassTestApi < HyperResource
            self.root = "http://example.com"
          end
          it 'can use a subclass of HR' do
            ## Test class-level setter
            api = SubclassTestApi.new
            api.root.must_equal "http://example.com"

            SubclassTestApi.root = "http://localhost:#{@port}/"
            api = SubclassTestApi.new
            root = api.get
            root.loaded.must_equal true
            root.class.to_s.must_equal 'SubclassTestApi::Root'
          end
        end

        describe 'configuration testing' do
          before do
            @api_short = WhateverAPI.new(
              :root => "http://localhost:#{@port}/",
              :faraday_options => {
                :request => {:timeout => 0.001}
              }
            )
          end

          it 'accepts custom timeout parameters' do
            p = proc { @api_short.get.slow_widgets.first }
            if defined?(Faraday::TimeoutError)
              p.must_raise(Faraday::TimeoutError)
            elsif defined?(Faraday::Error::TimeoutError)
              p.must_raise(Faraday::Error::TimeoutError)
            else
              raise RuntimeError, "Unknown version of Faraday."
            end
          end

          it 'passes the configuration to subclasses' do
            api_short_child = @api_short.get
            api_short_child.faraday_options[:request][:timeout].must_equal 0.001
          end
        end


      end # describe 'live tests'

    end # if
  end # describe HyperResource

end # unless !!ENV['NO_LIVE']
