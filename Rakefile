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

require 'rainbow'
require 'kramdown'
require 'smithy'
include Smithy
#require 'debugger'

desc "Generate markdown from html file"
task :generate_markdown, [:html_file] do |t, args|
  description_files = []
  description_file = File.expand_path(args[:html_file])

  if File.directory?(description_file)
    description_files = Dir.glob(description_file+"/*.html")
  else
    description_files << description_file
  end

  description_files.each do |description_file|
    markdown_file = description_file.gsub(/\.html$/,'') + ".markdown"
    notice_command description_file, " -> "+markdown_file
    begin
      f = File.open description_file
      content = f.read
      d = File.open(markdown_file, "w+")
      k = Kramdown::Document.new(content, :input => 'html')
      d.write(k.to_kramdown)
      d.close
    rescue => exception
      raise "#{exception}\nCannot parse #{description_file}"
    end
  end
end
