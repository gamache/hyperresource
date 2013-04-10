#  HyperResource
## a hypermedia client library for Ruby

## About

HyperResource is a client library for hypermedia web services.  It
is usable with no configuration other than API root endpoint, but
also allows incoming data types to be extended with Ruby code.

Currently HyperResource supports only the HAL+JSON hypermedia format.
HAL is discussed here: http://stateless.co/hal_specification.html

## Quick Tour

Set up API connection:

```ruby
api = HyperResource.new(root: 'https://api.example.com',
                        headers: {'Accept' => 'application/vnd.example.com.v1+json'},
                        auth: {basic: ['username', 'password']})
# => #<HyperResource:0xABCD1234 @root="https://api.example.com" @href="" @namespace=nil ... >
```

Now we can get the API's root resource, the gateway to everything else
on the API.

```ruby
root = api.get
# => #<HyperResource:0xABCD1234 @root="https://api.example.com" @href="" @namespace=nil ... >
```

What'd we get back?

```ruby
root.response_body
# => { 'message' => 'Welcome to the Example.com API',
#      'version' => 1,
#      '_links' => {
#        'self' => {'href' => '/'},
#        'users' => {'href' => '/users{?email,last_name}', 'templated' => true},
#        'forums' => {'href' => '/forums{?title}', 'templated' => true}
#      }
#    }
```

Lovely.  Let's find a user by their email.

```ruby
jdoe_user = api.users.where(email: "jdoe@example.com").first   # or,
jdoe_user = api.users(email: "jdoe@example.com").first         # same thing; .where is called implicitly 
                                                               # when accessing links
# => #<HyperResource:0x12312312 ...>

jdoe_user.response_body
# => { '_links' => {
#        'self' => {'href' => '/users?email=jdoe@example.com'}
#      },
#      '_embedded' => {
#        'users' => [
#          { 'first_name' => 'John',
#            'last_name' => 'Doe',
#            '_links' => {
#              'self' => {'href' => '/users/1'},
#              'comments' => {'href' => '/users/1/comments{?forum,date}', 'templated' => true}
#            }
#          }
#        ]
#      }
#    }
```

Some things happened magically here.  First, the `users` link has been
added as a method on the `api` object.  Then, calling `first` on a
not-yet-loaded object -- the `users` link -- loaded it automatically.
Finally, calling `first` on the object is a shorthand for returning the
first object in the first collection in the `_embedded` field (and,
therefore, the `self.objects` hash).


Now let's put it together.  Johnny ran his mouth in the
'Politics' forum last Monday and somehow managed to piss off the
entire Internet.  Let's try and satisfy the DDoSing horde by
amending his tone.

```ruby
forum = api.forums(title: 'Politics').first
jdoe_user.comments(date: '2013-04-01', forum: forum).each do |comment|
  comment.text = "OMG PUPPIES!!"
  comment.save
end
```

## Extending Data Types

If an API is returning data type information as part of the response --
and it really should be -- then we can assign those data types to
ruby classes so that they can be extended.

For example, in our hypothetical Example API above, a user object is
returned with a custom media type bearing a 'type=User' modifier.  We
will extend the User class with a few convenience methods.

```ruby
class ExampleAPI < HyperResource
  class User < ExampleAPI
    def full_name
      first_name + ' ' + last_name
    end
  end
end

api.namespace = ExampleApi

user = api.users.where(email: 'jdoe@example.com').first
# => #<ExampleApi::User:0xffffffff ...>

user.full_name
# => "John Doe"
```

Don't worry if your API uses some other method to indicate resource data
type; you can override the `data_type_name` method and implement your
own logic.

## Current Status

* Way alpha

* Read-only, at the moment (TODO: `save`, `post`, `put`, `patch`).


## Authorship and License

Copyright 2013 Pete Gamache,
[pete@gamache.org](mailto:pete@gamache.org).

If you got this far, you
should probably follow me on Twitter.  [@gamache](https://twitter.com/gamache)

Released under the MIT License.  See LICENSE.txt.
