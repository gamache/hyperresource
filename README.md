#  HyperResource
## a hypermedia client library for Ruby

## About

HyperResource is a client library for hypermedia web services.  It
is usable with no configuration other than API root endpoint, but
also allows incoming data types to be extended with ruby code.

Currently HyperResource supports only the HAL+JSON hypermedia format.
HAL is discussed here: http://stateless.co/hal_specification.html

## This Shit Be Out of Date

These docs were an idea about how HyperResource might work. It now works
a little, and a little differently from this.  The docs'll catch up
eventually.

## Standalone API Consumption

Set up API connection:

```ruby
api = HyperResource.new(:url    => 'https://api.example.com',
                        :accept => 'application/vnd.example.com.v1+json')
# => #<HyperResource:0xABCD1234 ... >
```

HyperResources are lazy-loaded.  You can force (re)loading like this:

```ruby
api.load
# => #<HyperResource:0xABCD1234 ... @type="Root">
```

But you generally will not need to.

Let's see what we got back from the API.

```ruby
api.response.content_type
# => "application/vnd.example.com.v1+json;type=Root"
```

```ruby
api.response.body
# => '{ "name": "Example API",
#       "version": 1,
#       "_links": {
#         {"users": {"href": "/users/{?last_name,email}", "templated": true},
#         {"forums": {"href": "/forums/{?date,title,tags}", "templated": true}
#         {"self":  {"href": "/"}}
#       }
#     }'
```

Let's find a user by their email.
    
```ruby
users = api.users.where(:email => "jdoe@example.com")
users = api.users(:email => "jdoe@example.com") # same thing
# => #<HyperResource:0x12312312 ...>
```

Nothing has really happened yet.  Lazy loading, remember?

```ruby
users.response.body
# => '{ "version": 1,
#       "_links": {"self": {"href": "/users/?email=jdoe@example.com"}},
#       "_embedded": {
#         "users": [ ... array of resources ]
#       }
#     }'
```

````ruby
jdoe_user = users.first
# => #<HyperResource:0xDEFABC12 ... @type="User">
############# TODO: figure out how to get data type from an embedded
#############          resource, since they don't come with a 
############           content-type. perhaps just load obj.self
```

When you call 'first' from a link called 'users' like that, you'd 
better sure that the API's going to return a collection of
something called 'users', inside the '_embedded' object.
That'll be in the human-readable API docs.

```ruby
jdoe_user.response.body
# => '{ "version": 1,
#       "first_name": "John",
#       "last_name": "Doe",
#       "email": "jdoe@example.com",
#       "_links": {
#         "self": {"href": "/users/1"},
#         "comments": {"href": "/users/1/comments{?forum,date}", "templated": true}
#       }
#     }'
```

Now let's put it together.  Johnny ran his mouth in the
'Politics' forum last Monday and somehow managed to piss off the
entire Internet.  Let's try and satisfy the DDoSing horde by
amending his tone.

```ruby
forum = api.forums(:title => 'Politics').first
jdoe_user.comments(:date => '2013-03-11', :forum => forum).each do |comment|
  comment.text = "OMG PUPPIES!!"
  comment.save!
end

#### could also use forum.href
```

## Extending Data Types

If an API is returning data type information as part of the response --
and it really should be -- then we can assign those data types to
ruby classes so that they can be extended.

For example, in our hypothetical Example API above, a user object is
returned with a custom media type bearing a 'type=User' modifier.  We
will extend the User class with a few convenience methods.

```ruby
module ExampleApi
  class User < HyperResource
    def full_name
      first_name + ' ' + last_name
    end
  
    def self.political_comments
      comments.where(:forum => root.forums(:title => 'Politics').first.href)
    end
  end
end

api.namespace = ExampleApi

user = api.users(:email => 'jdoe@example.com').first
# => #<ExampleApi::User:0xffffffff ...>

user.full_name
# => "John Doe"

user.political_comments.where(:date => '2012-03-11').first.text
# => "OMG PUPPIES!!"
```

    

## Authorship and License

Copyright 2013 Pete Gamache,
[pete@gamache.org](mailto:pete@gamache.org). 

If you got this far, you
should probably follow me on Twitter.  [@gamache](https://twitter.com/gamache) 

Released under the MIT License.  See LICENSE.txt.
