$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'hyper_resource/version'

Gem::Specification.new do |s|
  s.name    = 'hyperresource'
  s.version = HyperResource::VERSION
  s.date    = '2013-03-07'
  s.summary = 'Extensible hypermedia client for Ruby'
  s.authors = ['Pete Gamache']
  s.email   = 'pete@gamache.org'
  s.files   = Dir['lib/**/*']

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'uri_template'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
end
