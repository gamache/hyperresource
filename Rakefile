require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'test/lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

