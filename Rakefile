require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |task|
  task.libs << %w(test)
  task.pattern = "test/test_*.rb"
end

task :default => :test
