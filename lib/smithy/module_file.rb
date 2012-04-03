module Smithy
  class ModuleFile
    attr_accessor :package, :builds

    PackageModulePathName = "modulefile"
    SystemModulePathName  = "modulefiles"

    def initialize(args = {})
      @package = args[:package]
      @builds = @package.alternate_builds
    end

    def get_binding
      binding
    end

    def module_path
      File.join(package.version_directory, PackageModulePathName)
    end

    def module_file
      File.join(module_path, package.name, package.version)
    end

    def system_module_path
      File.join(package.software_root, SystemModulePathName)
    end

    def system_module_file
      File.join(system_module_path, package.name, package.version)
    end

    def create(args = {})
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]
      erb_file = File.join(@@smithy_bin_root, "/etc/templates/modulefile.erb")

      module_dir = File.join(module_path, package.name)
      FileUtils.mkdir_p(module_dir, options)

      new_module = module_file+"_#{Time.now.to_i}"
      old_module = module_file

      erb = ERB.new(File.read(erb_file), nil, "<>")
      File.open(new_module, "w+") do |f|
        f.write erb.result(binding)
      end

      FileOperations.install_file(new_module, old_module, options)
      FileUtils.rm_f(new_module) # Always remove

      FileOperations.make_group_writable(module_path, options.merge(:recursive => true))
      FileOperations.set_group(module_path, package.group, options.merge(:recursive => true))
    end

    def deploy(args = {})
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      g = system_module_path+"/*#{package.name}*/*#{package.version}*"
      module_matches = Dir.glob(g)
      if module_matches.size > 1
        notice_warn "Warning - multiple existing modulefiles found:"
        puts module_matches
      end

      if module_matches.empty?
        destination = system_module_file
      else
        destination = module_matches.first
      end

      notice "Deploying modulefile #{destination}"
      FileOperations.install_file module_file, destination, options
    end

  end
end
