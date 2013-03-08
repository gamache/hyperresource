require 'rake/testtask'
$LOAD_PATH << './test'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << './test/lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

