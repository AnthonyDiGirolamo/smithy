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
bin/smithy
bin/smithy
etc/autocomplete.bash
etc/autocomplete.zsh
etc/smithyrc
etc/templates/build/.owners
etc/templates/build/build-notes
etc/templates/build/dependencies
etc/templates/build/rebuild
etc/templates/build/relink
etc/templates/build/remodule
etc/templates/build/retest
etc/templates/build/status
etc/templates/package/.check4newver
etc/templates/package/.exceptions
etc/templates/package/description
etc/templates/package/support
etc/templates/package/versions
lib/smithy.rb
lib/smithy/format.rb
lib/smithy/helpers.rb
lib/smithy/package.rb
lib/smithy/file_operations.rb
lib/smithy_version.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','smithy.rdoc']
  s.rdoc_options << '--title' << 'smithy' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'smithy'
  #s.add_development_dependency('ruby-debug19')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_dependency('gli')
  s.add_dependency('open4')
  s.add_dependency('rainbow')
  s.add_dependency('terminal-table')
end
