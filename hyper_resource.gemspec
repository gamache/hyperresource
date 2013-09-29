require './lib/hyper_resource/version'

Gem::Specification.new do |s|
  s.name     = 'hyperresource'
  s.version  = HyperResource::VERSION
  s.date     = HyperResource::VERSION_DATE

  s.summary  = 'Extensible hypermedia client for Ruby'
  s.description = <<-EOT
    HyperResource is a hypermedia client library for Ruby.  Its goals are to
    interface directly with well-behaved hypermedia APIs, to allow the data
    returned from these APIs to optionally be extended by client-side code,
    and to present a modern replacement for ActiveResource.
  EOT
  s.homepage = 'https://github.com/gamache/hyperresource'
  s.authors  = ['Pete Gamache']
  s.email    = 'pete@gamache.org'

  s.files    = Dir['lib/**/*']
  s.license  = 'MIT'
  s.has_rdoc = true
  s.require_path = 'lib'

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'uri_template', '>= 0.5.2'
  s.add_dependency 'faraday',      '>= 0.8.6'

  s.add_development_dependency 'rake',     '>= 10.0.4'
  s.add_development_dependency 'minitest', '>= 4.7.0'
  s.add_development_dependency 'mocha',    '>= 0.13.3'
  s.add_development_dependency 'sinatra',  '>= 1.4.0'
end
