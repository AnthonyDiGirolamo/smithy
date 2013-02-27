module Smithy
  class Formula
    attr_accessor :formula_file, :name, :build_name, :prefix, :package, :module_setup

    def self.formula_name
      self.to_s.underscore.split("/").last.gsub /_formula$/, ""
    end

    def initialize(passed_package = nil)
      @formula_file = __FILE__
      raise "no install method implemented" unless self.respond_to?(:install)
      raise "homepage must be specified" if homepage.blank?
      raise "url must be specified" if url.blank?
      set_package(passed_package) if passed_package

      @module_setup = ""
      if ENV["MODULESHOME"]
        @modulecmd = "modulecmd sh"
        @modulecmd = "#{ENV["MODULESHOME"]}/bin/modulecmd sh" if File.exists?("#{ENV["MODULESHOME"]}/bin/modulecmd")
        @module_setup << `#{@module_setup} #{@modulecmd} purge 2>/dev/null` << " "
        if modules
          raise "modules must return a list of strings" unless modules.is_a? Array
          @module_setup << `#{@module_setup} #{@modulecmd} load #{modules.join(" ")}` << " "
        end
      end
    end

    def set_package(p)
      @package    = p
      @name       = p.name
      @version    = p.version
      @build_name = p.build_name
      @prefix     = p.prefix
    end

    # DSL Methods
    %w{ homepage url md5 sha1 sha2 sha256 modules }.each do |attr|
      class_eval %Q{
        def self.#{attr}(value = nil, &block)
          @#{attr} = block_given? ? block : value unless @#{attr}
          @#{attr}
        end
        def #{attr}
          @#{attr} = self.class.#{attr}.is_a?(Proc) ? instance_eval(&self.class.#{attr}) : self.class.#{attr} unless @#{attr}
          @#{attr}
        end
      }
    end

    # DLS Version Method, can set a version or guess based on the filename
    def self.version(value = nil)
      unless @version
        if value
          @version = value
        else
          @version = url_filename_version_number(self.url)
        end
      end
      @version
    end

    def version
      @version = self.class.version unless @version
      @version
    end

    def run_install
      install
      notice_success "SUCCESS #{@prefix}"
      return true
    end

    def module_list
      if ENV['MODULESHOME']
        notice "module list"
        Kernel.system @module_setup + "#{@modulecmd} list 2>&1"
      end
    end

    def patch(content)
      patch_file_name = "patch.diff"
      File.open(patch_file_name, "w+") do |f|
        f.write(content)
      end
      `patch -p1 <#{patch_file_name}`
    end

    def system(*args)
      notice args.join(' ')
      if args.first == :nomodules
        args.shift
        Kernel.system args.join(' ')
      else
        Kernel.system @module_setup + args.join(' ')
      end
      if $?.exitstatus != 0
        raise <<-EOF.strip_heredoc
          The last command exited with status: #{$?.exitstatus}
            Formula: #{formula_file_path}
            Build Directory: #{@package.source_directory}
        EOF
      end
    end

    def check_dependencies
      @depends_on = [depends_on] if depends_on.is_a? String
      missing_packages = []
      depends_on.each do |package|
        name, version, build = package.split('/')
        path = Package.all(:name => name, :version => version, :build => build).first
        if path
          p = Package.new(:path => path)
          new_name = p.name.underscore
          class_eval %Q{
            def #{new_name}
              @#{new_name} = Package.new(:path => "#{path}") if @#{new_name}.nil?
              @#{new_name}
            end
          }
        else
          missing_packages << package
          #TODO build package instead?
        end
      end
      unless missing_packages.empty?
        raise "#{self.class} depends on: #{missing_packages.join(" ")}"
      end
    end

  end #class Formula
end #module Smithy
