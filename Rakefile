# For Bundler.with_clean_env
require 'bundler/setup'

require 'rdoc/task'
require 'rake/clean'
require 'cucumber'
require 'cucumber/rake/task'

task :default => :features

# Run Cucumber Tests
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress -x"
  t.fork = false
end

# RDoc Generation
Rake::RDocTask.new do |rd|
  rd.main = "smithy.rdoc"
  rd.rdoc_files.include("smithy.rdoc","lib/**/*.rb","bin/**/*")
  rd.title = 'Smithy'
end

# rake 'generate_markdown[DIR]'
desc "Generate markdown from html file"
task :generate_markdown, [:html_file] do |t, args|
  require 'rainbow'
  require 'kramdown'
  require 'smithy'
  include Smithy
  #require 'debugger'

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

PACKAGE_NAME = "smithy"
require_relative 'lib/smithy_version.rb'
VERSION = Smithy::VERSION
TRAVELING_RUBY_VERSION = "20150210-2.1.5"

desc "Package your app"
task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx']

namespace :package do
  namespace :linux do
    desc "Package your app for Linux x86"
    task :x86 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz"] do
      create_package("linux-x86")
    end

    desc "Package your app for Linux x86_64"
    task :x86_64 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package("linux-x86_64")
    end
  end

  desc "Package your app for OS X"
  task :osx => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
    create_package("osx")
  end

  desc "Install gems to local directory"
  task :bundle_install do
    if RUBY_VERSION !~ /^2\.1\./
      abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
    end
    sh "rm -rf packaging/tmp"
    sh "mkdir packaging/tmp"
    sh "cp Gemfile Gemfile.lock packaging/tmp/"
    Bundler.with_clean_env do
      sh "cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development"
    end
    sh "rm -rf packaging/tmp"
    sh "rm -f packaging/vendor/*/*/cache/*"
  end
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz" do
  download_runtime("linux-x86")
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime("linux-x86_64")
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
  download_runtime("osx")
end

def create_package(target)
  package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/app"
  sh "cp -r bin lib man etc #{package_dir}/lib/app/"
  sh "mkdir #{package_dir}/lib/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/ruby"
  sh "cp packaging/wrapper.sh #{package_dir}/#{PACKAGE_NAME}"
  sh "cp -r environment.sh #{package_dir}/"
  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  sh "cp Gemfile Gemfile.lock #{package_dir}/lib/vendor/"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"
  if !ENV['DIR_ONLY']
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
    sh "rm -rf #{package_dir}"
  end
end

def download_runtime(target)
  sh "cd packaging && curl -L -O --fail " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end

