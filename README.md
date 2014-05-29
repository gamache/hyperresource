# HyperResource [![Build Status](https://travis-ci.org/gamache/hyperresource.png?branch=master)](https://travis-ci.org/gamache/hyperresource)

HyperResource is a Ruby client library for hypermedia web services.

HyperResource makes using a hypermedia API feel like calling plain old
methods on plain old objects.

It is usable with no configuration other than API root endpoint, but
also allows incoming data types to be extended with Ruby code.

HyperResource supports the 
[HAL+JSON hypermedia format](http://stateless.co/hal_specification.html),
with support for Siren and other hypermedia formats planned.

For more insight into HyperResource's goals and design,
[read the paper](http://petegamache.com/wsrest2014-gamache.pdf)!

## Hypermedia in a Nutshell

Hypermedia APIs return a list of hyperlinks with each response.  These
links, each of which has a relation name or "rel", represent everything
you can do to, with, or from the given response.  They are URLs which
can take arguments.  The consumer of the hypermedia API uses these
links to access the API's entire functionality.

A primary advantage to hypermedia APIs is that a client library can
write itself based on the hyperlinks coming back with each response.
This removes both the chore of writing a custom client library in the
first place, and also the process of pushing client updates to your
users.

## HyperResource Philosophy

An automatically-generated library can and should feel as comfortable as a
custom client library.  Hypermedia brings many promises, but this is one
we can deliver on.

If you're an API user, HyperResource will help you consume a hypermedia
API with short, direct, elegant code.
If you're an API designer, HyperResource is a great default client, or a
smart starting point for a rich SDK.

Link-driven APIs are the future, and proper tooling can make it The Jetsons
instead of The Road Warrior.

## Install It

Nothing special is required, just: `gem install hyperresource`

HyperResource works on Ruby 1.8.7 to present, and JRuby in 1.8 mode or
above.

HyperResource uses the 
[uri_template](https://github.com/hannesg/uri_template)
and [Faraday](https://github.com/lostisland/faraday)
gems.  

## Use It - Zero Configuration

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
api.get
# => #<HyperResource:0xABCD1234 @root="https://api.example.com" @href="" @namespace=nil ... >
```

What'd we get back?

```ruby
api.body
# => { 'message' => 'Welcome to the Example.com API',
#      'version' => 1,
#      '_links' => {
#        'curies' => [{
#          'name' => 'example',
#          'templated' => true,
#          'href' => 'https://api.example.com/rels/{rel}'
#        }],
#        'self' => {'href' => '/'},
#        'example:users' => {'href' => '/users{?email,last_name}', 'templated' => true},
#        'example:forums' => {'href' => '/forums{?title}', 'templated' => true}
#      }
#    }
```

Lovely.  Let's find a user by their email.

```ruby
jdoe_user = api.users(email: "jdoe@example.com").first
# => #<HyperResource:0x12312312 ...>
```

HyperResource has performed some behind-the-scenes expansions here.

First, the `example:users` link was
added to the `api` object at the time the resource was
loaded with `api.get`.  And since the link rel has a 
[CURIE prefix](http://tools.ietf.org/html/draft-kelly-json-hal-06#section-8.2),
HyperResource will allow a shortened version of its name, `users`.

Then, calling `first` on the `users` link
followed the link and loaded it automatically.

Finally, calling `first` on the resource containing one set of
embedded objects -- like this one -- delegates the method to
`.objects.first`, which returns the first object in the resource.

Here are some equivalent expressions to the above.  HyperResource offers
a very short, expressive syntax as its primary interface,
but you can always fall back to explicit syntax if you like or need to.


```
api.users(email: "jdoe@example.com").first
api.get.users(email: "jdoe@example.com").first
api.get.links.users(email: "jdoe@example.com").first
api.get.links['users'].where(email: "jdoe@example.com").first
api.get.links['users'].where(email: "jdoe@example.com").get.first
api.get.links['users'].where(email: "jdoe@example.com").get.objects.first[1][0]
```

## Use It - ActiveResource-style

If an API is returning data type information as part of the response,
then we can assign those data types to ruby classes so that they can
be extended.

For example, in our hypothetical Example API above, a user object is
returned with a custom media type bearing a 'type=User' modifier.  We
will extend the User class with a few convenience methods.

```ruby
class ExampleAPI < HyperResource
  self.root = 'https://api.example.com'
  self.headers = {'Accept' => 'application/vnd.example.com.v1+json'}
  self.auth = {basic: ['username', 'password']}

  class User < ExampleAPI
    def full_name
      first_name + ' ' + last_name
    end
  end
end

api = ExampleApi.new

user = api.users.where(email: 'jdoe@example.com').first
# => #<ExampleApi::User:0xffffffff ...>

user.full_name
# => "John Doe"
```

Don't worry if your API uses some other mechanism to indicate resource data
type; you can override the `.get_data_type` method and
implement your own logic.

## Configuration for Multiple Hosts

HyperResource supports the concept of different APIs connected in one
ecosystem by providing a mechanism to scope configuration parameters by
a URL mask.  This allows a simple way to provide separate
authentication, headers, etc. to different services which link to each
other.

As a toy example, consider two servers.  `http://localhost:12345/` returns:

```json
{ "name": "Server One",
  "_links": {
    "self":       {"href": "http://localhost:12345/"},
    "server_two": {"href": "http://localhost:23456/"}
  }
}
```

And `http://localhost:23456/` returns:

```json
{ "name": "Server Two",
  "_links": {
    "self":       {"href": "http://localhost:23456/"},
    "server_one": {"href": "http://localhost:12345/"}
  }
}
```

The following configuration would ensure proper namespacing of the two
servers' response objects:

```ruby
class APIEcosystem < HyperResource
  self.config(
    "localhost:12345" => {"namespace" => "ServerOneAPI"},
    "localhost:23456" => {"namespace" => "ServerTwoAPI"}
  )
end

root_one = APIEcosystem.new(root: ‘http://localhost:12345’).get
root_one.name      # => ‘Server One’
root_one.url       # => ‘http://localhost:12345’
root_one.namespace # => ServerOneAPI

root_two = root_one.server_two.get
root_two.name      # => ‘Server Two’
root_two.url       # => ‘http://localhost:23456’
root_two.namespace # => ServerTwoAPI
```

Fuzzy matching of URL masks is provided by the
[FuzzyURL](https://github.com/gamache/fuzzyurl/) gem; check there for
full documentation of URL mask syntax.

## Error Handling

HyperResource raises a `HyperResource::ClientError` on 4xx responses,
and `HyperResource::ServerError` on 5xx responses.  Catch one or both
(`HyperResource::ResponseError`).  The exceptions contain as much of
`cause` (internal exception which led to this one), `response`
(`Faraday::Response` object), and `body` (the decoded response
as a `Hash`) as is possible at the time.

## Contributors

Many thanks to the people who've sent pull requests and improved this code:

* Jean-Charles d'Anthenaise Sisk ([@jasisk](https://github.com/jasisk))
* Ian Asaff ([@montague](https://github.com/montague))
* Julien Blanchard ([@julienXX](https://github.com/julienXX))
* Andrew Rollins ([@andrew311](https://github.com/andrew311))
* Étienne Barrié ([@etiennebarrie](https://github.com/etiennebarrie))
* James Martelletti ([@jmartelletti](https://github.com/jmartelletti))
* Frank Macreery ([@fancyremarker](https://github.com/fancyremarker))
* Chris Rollock ([@Sastafer](https://github.com/Sastafer))

## Authorship and License

Copyright 2013-2014 Pete Gamache, [pete@gamache.org](mailto:pete@gamache.org).

Released under the MIT License.  See LICENSE.txt.

If you got this far, you should probably follow me on Twitter.
[@gamache](https://twitter.com/gamache)


