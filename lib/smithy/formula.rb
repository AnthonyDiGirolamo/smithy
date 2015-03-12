module Smithy
  class Formula
    attr_accessor :formula_file, :name, :build_name, :prefix, :package, :module_setup

    def self.formula_name
      self.to_s.underscore.split("/").last.gsub(/_formula$/, "")
    end
    def formula_name
      self.class.formula_name
    end

    def initialize(passed_package = nil)
      @formula_file = __FILE__
      raise "no install method implemented" unless self.respond_to?(:install)
      raise "homepage must be specified" if homepage.blank?
      raise "url must be specified" if url.blank?
      if passed_package
        set_package(passed_package)
      else
        # guess name and build_name
        @name = self.formula_name
        @build_name = operating_system
      end

      if ENV["MODULESHOME"]
        @modulecmd = "modulecmd sh"
        @modulecmd = "#{ENV["MODULESHOME"]}/bin/modulecmd sh" if File.exists?("#{ENV["MODULESHOME"]}/bin/modulecmd")
      end
    end

    # setup module environment by purging and loading only what's needed
    def initialize_modules
      @module_setup = ""
      @module_commands = @modules = nil # re-evaluates the blocks

      raise "please specify modules OR modules_command, not both" if modules.present? && module_commands.present?
      raise "module_commands method must return an array" if module_commands.present? && module_commands.class != Array

      if ENV["MODULESHOME"]
        @module_commands = @modules = nil # re-evaluates the blocks
        if modules.present?
          @module_setup << `#{@module_setup} #{@modulecmd} purge 2>/dev/null` << " "
          raise "modules must return a list of strings" unless modules.is_a? Array
          @module_setup << `#{@module_setup} #{@modulecmd} load #{modules.join(" ")}` << " "
        elsif module_commands.present?
          module_commands.each do |command|
            @module_setup << `#{@module_setup} #{@modulecmd} #{command}` << " "
          end
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
    %w{ homepage url md5 sha1 sha2 sha256 modules module_commands depends_on modulefile }.each do |attr|
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

    def self.params(params_hash)
      raise "params method must be given a hash" unless params_hash.is_a?(Hash)

      notice "Using Parameters:"
      params_hash.each do |attr, value|
        attr = attr.to_s
        class_eval %Q{
          def self.#{attr}(value = nil)
            @#{attr} = value unless @#{attr}
            @#{attr}
          end
          def #{attr}
            @#{attr} = self.class.#{attr} unless @#{attr}
            @#{attr}
          end
        }
        self.send(attr, value)
      end
      notice_params params_hash
    end

    # DSL Version Method, can set a version or guess based on the filename
    def self.version(value = nil)
      unless @version
        if value
          @version = value
        else
          @version = url_filename_version_number(url) if url.present?
        end
      end
      @version
    end

    def version
      @version = self.class.version unless @version
      @version
    end

    # DSL Version Method, can set a version or guess based on the filename
    def self.disable_group_writable(value = true)
      @disable_group_writable = true
      @disable_group_writable
    end

    def group_writable?
      ! self.class.instance_variables.include?(:@disable_group_writable)
    end

    def run_install
      initialize_modules
      install
      notice_success "SUCCESS #{@prefix}"
      return true
    end

    def create_modulefile
      return false if modulefile.blank?
      notice "Creating Modulefile for #{package.prefix}"
      m = ModuleFile.new :package => package
      FileUtils.mkdir_p(File.dirname(m.module_file))
      FileOperations.render_erb(:erb_string => modulefile, :binding => m.get_binding, :destination => m.module_file)
      FileOperations.make_group_writable(m.module_path, :recursive => true)
      FileOperations.set_group(m.module_path, package.group, :recursive => true)
      return true
    end

    def module_list
      if ENV['MODULESHOME']
        notice "module list"
        Kernel.system @module_setup + "#{@modulecmd} list 2>&1"
      end
    end

    def module_is_available?(mod)
      module_avail = `#{module_setup} #{@modulecmd} avail #{mod} 2>&1`
      if module_avail =~ /#{mod}/
        true
      else
        false
      end
    end

    def module_environment_variable(mod, var)
      module_display = `#{module_setup} #{@modulecmd} display #{mod} 2>&1`
      if module_display =~ /^(\S+)\s+#{var}\s+(.*)$/
        return $2.strip
      else
        return ""
      end
    end

    def fail_command
      $stdout.flush
      $stderr.flush
      raise <<-EOF.strip_heredoc
        The last command exited with status: #{$?.exitstatus}
          Formula: #{formula_file}
          Build Directory: #{@package.source_directory}
      EOF
    end

    def patch(content, *args)
      patch_file_name = "patch.diff"
      File.open(patch_file_name, "w+") do |f|
        f.write(content)
      end
      args << "-p1" if args.empty?
      patch_command = "patch #{args.join(' ')} <#{patch_file_name}"
      notice patch_command
      Kernel.system patch_command
      fail_command if $?.exitstatus != 0
    end

    def system(*args)
      notice args.join(' ')
      if args.first == :nomodules
        args.shift
        Kernel.system args.join(' ')
      else
        Kernel.system @module_setup + args.join(' ')
      end
      fail_command if $?.exitstatus != 0
    end

    def python_command(*args)
      python_version_output = `#{@module_setup} python --version 2>&1`
      v = python_version_output.chomp.strip.split.last
      if v =~ /^(\d+\.)?(\d+\.)?(\d+)$/
        pyver = $1 + $2.delete(".")
        pylibdir = "#{prefix}/lib/python#{pyver}/site-packages"
        FileUtils.mkdir_p pylibdir
        system "PYTHONPATH=$PYTHONPATH:#{pylibdir} python ", args.join(" ")
      end
    end

    def check_dependencies
      return true unless depends_on
      @depends_on = [depends_on] if depends_on.is_a? String
      missing_packages = []
      notice "Searching for dependencies"
      depends_on.each do |package|
        name, version, build = package.split('/')
        path = Package.all(:name => name, :version => version, :build => build).first
        if path
          notice_using(path)
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
