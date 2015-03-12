# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','smithy_version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'software_smithy'
  s.version = Smithy::VERSION
  s.author = 'Anthony DiGirolamo'
  s.email = 'anthony.digirolamo@gmail.com'
  s.homepage = 'https://github.com/AnthonyDiGirolamo/smithy'
  s.platform = Gem::Platform::RUBY
  s.summary = %q{Smithy can help maintain a collection of software installed from source. Typically, many different versions built with different compilers.}
  s.license = "BSD"
  s.files = %w(
bin/smithy
etc/completion/smithy-completion.bash
etc/completion/zsh/_smithy
etc/templates/formula.rb.erb
etc/templates/modulefile.erb
etc/templates/build/.owners
etc/templates/build/build-notes
etc/templates/build/dependencies
etc/templates/build/rebuild
etc/templates/build/relink
etc/templates/build/remodule.erb
etc/templates/build/retest
etc/templates/build/status
etc/templates/package/.check4newver
etc/templates/package/.exceptions
etc/templates/package/description
etc/templates/package/description.markdown
etc/templates/package/support
etc/templates/package/versions
etc/templates/web/alphabetical.html.erb
etc/templates/web/version_table.html.erb
etc/templates/web/version_list.html.erb
etc/templates/web/machine_version_table.html.erb
etc/templates/web/category.html.erb
etc/templates/web/package.html.erb
etc/templates/web/all.html.erb
lib/smithy.rb
lib/smithy/config.rb
lib/smithy/description.rb
lib/smithy/download_cache.rb
lib/smithy/file_operations.rb
lib/smithy/format.rb
lib/smithy/formula.rb
lib/smithy/formula_command.rb
lib/smithy/helpers.rb
lib/smithy/module_file.rb
lib/smithy/package.rb
lib/smithy_version.rb
man/man1/smithy.1
man/man5/smithyformula.5
  )
  # s.files += Dir["formulas/*"]
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['smithy.rdoc']
  s.rdoc_options << '--title' << 'smithy' << '--main' << 'smithy.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'smithy'
  s.add_development_dependency('awesome_print')
  s.add_development_dependency('interactive_editor')
  s.add_development_dependency('cucumber')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('ronn')
  s.add_development_dependency('rspec')
  s.add_development_dependency('fuubar')
  s.add_development_dependency('debugger')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-doc')
  s.add_dependency('gli', '= 2.10.0')
  s.add_dependency('kramdown', '= 1.4.0')
  s.add_dependency('open4', '= 1.3.4')
  s.add_dependency('rainbow', '= 1.1.4')
  s.add_dependency('activesupport', '= 3.2.14')
  s.add_dependency('terminal-table', '>= 1.4.5')
end
