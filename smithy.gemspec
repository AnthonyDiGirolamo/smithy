# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','smithy_version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'software_smithy'
  s.version = Smithy::VERSION
  s.author = 'Anthony DiGirolamo'
  s.email = 'anthony.digirolamo@gmail.com'
  s.homepage = 'http://anthonydigirolamo.github.com'
  s.platform = Gem::Platform::RUBY
  s.summary = %q{Smithy can help maintain a collection of software installed from source. Typically, many different versions built with different compilers.}
  s.files = %w(
bin/smith
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','smithy.rdoc']
  s.rdoc_options << '--title' << 'smithy' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'smith'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_dependency('gli')
  s.add_dependency('open4')
end
