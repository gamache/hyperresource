require 'test_helper'
require 'sinatra'
require 'json'
require File.expand_path('../two_test_servers.rb', __FILE__)


if ENV['NO_LIVE']
  puts "Skipping live tests."
  exit
elsif RUBY_VERSION[0..2] == '1.8'
  puts "Live tests don't run on Ruby 1.8; skipping."
  exit
end


launched_servers = false
server_one = nil
server_two = nil

MiniTest::Unit.after_tests do
  server_one.kill
  server_two.kill
end

describe 'APIEcosystem' do
  launched_servers = false
  before do
    unless launched_servers
      server_one = Thread.new do
        Rack::Handler::WEBrick.run(
          ServerOne.new,
          :Port => PORT_ONE.to_i,
          :AccessLog => [],
          :Logger => WEBrick::Log::new("/dev/null", 7)
        )
      end
      server_two = Thread.new do
        Rack::Handler::WEBrick.run(
          ServerTwo.new,
          :Port => PORT_TWO.to_i,
          :AccessLog => [],
          :Logger => WEBrick::Log::new("/dev/null", 7)
        )
      end

      retries = 5
      begin
        HyperResource.new(root: "http://localhost:#{PORT_ONE}").get
        HyperResource.new(root: "http://localhost:#{PORT_TWO}").get
      rescue Exception => e
        if ENV['DEBUG']
          puts "#{e.class}: #{e}" if ENV['DEBUG']
          puts caller[0..10]
          retries -= 1
          raise e if retries == 0
        end
        sleep 0.2
        retry if retries > 0
      end

      launched_servers = true
    end
  end


  class APIEcosystem < HyperResource
    self.config(
      "localhost:#{PORT_ONE}" => {
        "namespace"          => "ServerOneAPI",
        "default_attributes" => {"server" => "1"},
        "headers"            => {"X-Server" => "1"},
        "auth"               => {:basic => ["server_one", ""]},
        "faraday_options"    => {:request => {:timeout => 1}},
      },
      "localhost:#{PORT_TWO}" => {
        "namespace"          => "ServerTwoAPI",
        "default_attributes" => {"server" => "2"},
        "headers"            => {"X-Server" => "2"},
        "auth"               => {:basic => ["server_two", ""]},
        "faraday_options"    => {:request => {:timeout => 2}},
      }
    )
  end

  describe 'live tests' do

    it 'uses the right config for server one' do
      root_one = APIEcosystem.new(:root => "http://localhost:#{PORT_ONE}").get
      root_one.class.to_s.must_equal 'ServerOneAPI'
      root_one.sent_params.must_equal({"server" => "1"})
      root_one.headers['X-Server'].must_equal "1"
      root_one.auth.must_equal({:basic => ["server_one", ""]})
      root_one.faraday_options.must_equal({:request => {:timeout => 1}})
    end

    it 'uses the right config for server two' do
      root_two = APIEcosystem.new(:root => "http://localhost:#{PORT_TWO}").get
      root_two.class.to_s.must_equal 'ServerTwoAPI'
      root_two.sent_params.must_equal({"server" => "2"})
      root_two.headers['X-Server'].must_equal "2"
      root_two.auth.must_equal({:basic => ["server_two", ""]})
      root_two.faraday_options.must_equal({:request => {:timeout => 2}})
    end

    it 'can go back and forth' do
      root_one = APIEcosystem.new(:root => "http://localhost:#{PORT_ONE}").get
      root_two = root_one.server_two.server_one.server_two.get
      root_two.class.to_s.must_equal 'ServerTwoAPI'
    end

  end

end

