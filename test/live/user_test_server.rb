require 'sinatra'
require 'json'

USERS_PORT    = ENV['HR_USERS_PORT']    || 25491
COMMENTS_PORT = ENV['HR_COMMENTS_PORT'] || 25492

USERS    = "http://localhost:#{USERS_PORT}/"
COMMENTS = "http://localhost:#{COMMENTS_PORT}/"

def user_path(user)
  "/users/#{u.id}"
end

def user_url(user)
  "http://localhost:#{USERS_PORT}/users/#{user.id}"
end

def comments_url(user)
  "http://localhost:#{COMMENTS_PORT}/comments?user=#{user_url(user)}"
end

class User
  attr_accessor :id, :first_name, :last_name, :email

  def initialize(params={})
    self.id = sprintf("%.8x", rand(0xFFFFFFFF))
    self.first_name = params[:first_name]
    self.last_name = params[:last_name]
    self.email = params[:email]
  end

  def as_hal
    { :first_name => first_name,
      :last_name => last_name,
      :email => email,
      :_data_type => 'User',
      :_links => {
        :self => {:href => user_path(self)},
        :comments => {:href => comments_url(self)},
        :root => {:href => '/'}
      }
    }
  end

  def to_hal; JSON.dump(as_hal) end
end

class UserTestServer < Sinatra::Base
  get '/' do
    headers['Content-type'] = 'application/vnd.example.v1+hal+json;type=Root'
    JSON.dump(
      :message => "Welcome to the User Test Server",
      :_data_type => "Root",
      :_links => {
        :self => {:href => '/'},
        :users => {:href => "/users{id,email}", :templated => true}
      }
    )
  end

  get '/users' do
    if params["id"]
    elsif params["email"]
    else
    end
  end

end
