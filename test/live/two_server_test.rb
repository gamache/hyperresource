require 'test_helper'
require 'sinatra'
require 'json'

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

PORT_ONE = ENV['TEST_PORT_ONE'] || 42774
PORT_TWO = ENV['TEST_PORT_TWO'] || 42775

class ServerOne < Sinatra::Base
  get '/' do
    params = request.env['rack.request.query_hash']
    headers['Content-Type'] = 'application/hal+json'
    <<-EOT
      { "name": "Server One",
        "sent_params": #{JSON.dump(params)},
        "_links": {
          "self":       {"href": "http://localhost:#{PORT_ONE}/"},
          "server_two": {"href": "http://localhost:#{PORT_TWO}/"}
        }
      }
    EOT
  end
end

class ServerTwo < Sinatra::Base
  get '/' do
    params = request.env['rack.request.query_hash']
    headers['Content-Type'] = 'application/hal+json'
    <<-EOT
      { "name": "Server Two",
        "sent_params": #{JSON.dump(params)},
        "_links": {
          "self":       {"href": "http://localhost:#{PORT_TWO}/"},
          "server_one": {"href": "http://localhost:#{PORT_ONE}/"}
        }
      }
    EOT
  end
end

class APIEcosystem < HyperResource
  self.config(
    "localhost:#{PORT_ONE}" => {"namespace" => "ServerOneAPI"},
    "localhost:#{PORT_TWO}" => {"namespace" => "ServerTwoAPI"}
  )
end

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


  describe 'live tests' do

    it 'loads the ServerOne root resource into its proper namespace' do
      root_one = APIEcosystem.new(:root => "http://localhost:#{PORT_ONE}").get
      root_one.class.to_s.must_equal 'ServerOneAPI'
    end

    it 'loads the ServerTwo root resource into its proper namespace' do
      root_two = APIEcosystem.new(:root => "http://localhost:#{PORT_TWO}").get
      root_two.class.to_s.must_equal 'ServerTwoAPI'
    end

  end



end


