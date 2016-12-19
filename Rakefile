require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

load "lib/appcanary/tasks/appcanary/check.rake"
load "lib/appcanary/tasks/appcanary/monitor.rake"

task :default => :test
