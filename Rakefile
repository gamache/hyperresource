require 'rake/testtask'
require './lib/hyper_resource/version'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :release do
  system(<<-EOT)
    git checkout master
    git rm -r doc
    yard
    git add doc
    git commit -m 'generated doc/'
    git tag release-#{HyperResource::VERSION}
    git push origin master
    gem build hyper_resource.gemspec
    gem push hyperresource-#{HyperResource::VERSION}.gem
  EOT
end

task :test_server do
  require './test/live/live_test_server'
  port = ENV['PORT'] || ENV['port'] || 3000
  Rack::Handler::WEBrick.run(LiveTestServer.new, :Port => port)
end

