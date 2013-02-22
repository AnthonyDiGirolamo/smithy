module Smithy
  class Formula
    def self.formula_name
      self.to_s.underscore.gsub /_formula$/, ""
    end

    def self.install
      raise "no install method implemented"
    end

    # def self.homepage(value = nil)
    #   @homepage = value unless @homepage
    #   @homepage
    # end

    # def self.url(value = nil)
    #   @url = value unless @url
    #   @url
    # end

    %w{ url homepage }.each do |attr|
      class_eval %Q{
        def self.#{attr}(value = nil)
          @#{attr} = value unless @#{attr}
          @#{attr}
        end

        def #{attr}
          @#{attr} = self.class.#{attr} unless @#{attr}
        end
      }
    end
  end

#   class Formula
#     attr_accessor :module_setup, :formula_file_path

#     def package
#       @package
#     end

#     def package=(p)
#       @package    = p
#       @name       = @package.name
#       @version    = @package.version
#       @build_name = @package.build_name
#       @prefix     = @package.prefix
#       return @package
#     end

#     def initialize(args = {})
#       self.package = args[:package] if args[:package]

#       @formula_file_path = args[:path] if args[:path]

#       @module_setup = ''

#       if ENV['MODULESHOME']
#         @modulecmd = "modulecmd sh"
#         @modulecmd = "#{ENV['MODULESHOME']}/bin/modulecmd sh" if File.exists?("#{ENV['MODULESHOME']}/bin/modulecmd")
#         @module_setup << `#{@module_setup} #{@modulecmd} purge 2>/dev/null`
#         @module_setup << ' '
#         if modules
#           @module_setup << `#{@module_setup} #{@modulecmd} load #{@modules.join(' ')}`
#           @module_setup << ' '
#         end
#       end

#       check_dependencies if depends_on
#     end

#     def check_dependencies
#       @depends_on = [depends_on] if depends_on.is_a? String
#       missing_packages = []
#       depends_on.each do |package|
#         name, version, build = package.split('/')
#         path = Package.all(:name => name, :version => version, :build => build).first
#         if path
#           p = Package.new(:path => path)
#           new_name = p.name.underscore
#           class_eval %Q{
#             def #{new_name}
#               @#{new_name} = Package.new(:path => "#{path}") if @#{new_name}.nil?
#               @#{new_name}
#             end
#           }
#         else
#           missing_packages << package
#           #TODO build package instead?
#         end
#       end

#       unless missing_packages.empty?
#         raise "#{self.class} depends on: #{missing_packages.join(" ")}"
#       end
#     end

#     def patch(content)
#       patch_file_name = "patch.diff"
#       File.open(patch_file_name, "w+") do |f|
#         f.write(content)
#       end
#       `patch -p1 <#{patch_file_name}`
#     end

#     def system(*args)
#       notice args.join(' ')
#       if args.first == :nomodules
#         args.shift
#         Kernel.system args.join(' ')
#       else
#         Kernel.system @module_setup + args.join(' ')
#       end
#       if $?.exitstatus != 0
#         raise <<-EOF.strip_heredoc
#           The last command exited with status: #{$?.exitstatus}
#             Formula: #{formula_file_path}
#             Build Directory: #{@package.source_directory}
#         EOF
#       end
#     end

#     def run_install
#       install
#       notice_success "SUCCESS #{@package.prefix}"
#       return true
#     end

#     def module_list
#       if ENV['MODULESHOME']
#         notice "module list"
#         Kernel.system @module_setup + "#{@modulecmd} list 2>&1"
#       end
#     end

#     # DSL and instance methods

#     %w{depends_on url homepage md5 sha1 sha2 sha256 version name build_name prefix modules modulefile}.each do |attr|
#       class_eval %Q{
#         def self.#{attr}(value = nil, &block)
#           if block_given?
#             @#{attr} = block
#           elsif value
#             @#{attr} = value
#           end

#           @#{attr}
#         end

#         def #{attr}
#           unless @#{attr}
#             if self.class.#{attr}.is_a?(Proc)
#               @#{attr} = instance_eval(&self.class.#{attr})
#             else
#               @#{attr} = self.class.#{attr}
#             end
#           end

#           @#{attr}
#         end
#       }
#     end

#   end #class Formula
end #module Smithy
