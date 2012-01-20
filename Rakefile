require 'rubygems'
require 'rdoc/task'
require 'rake/clean'
require 'rubygems/package_task'

require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty -x"
  t.fork = false
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Your application title'
end

spec = eval(File.read('smithy.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

# Unit Tests
# require 'rake/testtask'
# Rake::TestTask.new do |t|
#   t.libs << "test"
#   t.test_files = FileList['test/tc_*.rb']
# end

task :default => :features
