module Smithy
  class ModuleFile
    attr_accessor :package, :builds

    PackageModulePathName = "modulefile"
    SystemModulePathName  = "modulefiles"

    Environments = [
      {:prg_env => "PrgEnv-gnu",       :compiler_name => "gcc",       :human_name => "gnu",       :regex => /(gnu|gcc)(.*)/,
        :build_name_regex => /(gnu|gcc)([\d\.]+)/ },
      {:prg_env => "PrgEnv-pgi",       :compiler_name => "pgi",       :human_name => "pgi",       :regex => /(pgi)(.*)/,
        :build_name_regex => /(pgi)([\d\.]+)/ },
      {:prg_env => "PrgEnv-intel",     :compiler_name => "intel",     :human_name => "intel",     :regex => /(intel)(.*)/,
        :build_name_regex => /(intel)([\d\.]+)/ },
      {:prg_env => "PrgEnv-cray",      :compiler_name => "cce",       :human_name => "cray",      :regex => /(cce|cray)(.*)/,
        :build_name_regex => /(cce|cray)([\d\.]+)/ }
    ]
      #{:prg_env => "PrgEnv-pathscale", :compiler_name => "pathscale", :human_name => "pathscale", :regex => /(pathscale)(.*)/}

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
      notice "Creating Modulefile for #{package.prefix}"
      notice_warn "Dry Run! (no files will be created or changed)" if args[:dry_run]

      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      FileUtils.mkdir_p(File.join(module_path, package.name), options)

      FileOperations.render_erb :destination => module_file,
        :erb => File.join(@@smithy_bin_root, "/etc/templates/modulefile.erb"),
        :binding => get_binding, :options => options

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
      install_dir = File.join(system_module_path, package.name)
      FileOperations.make_directory install_dir, options
      FileOperations.install_file module_file, destination, options
      FileOperations.make_group_writable(install_dir, options.merge(:recursive => true))
      FileOperations.set_group(install_dir, package.group, options.merge(:recursive => true))
    end

    def module_build_list(package, builds, args = {})
      output = ""
      notice "Multiple Builds Found"
      notice_info "Build Name".rjust(25)+"   Required Modules"
      Environments.each_with_index do |e,i|
        if i == 0
          output << "if "
        else
          output << "} elseif "
        end
        output << "[ is-loaded #{e[:prg_env]} ] {\n"
        if j=builds.index{|b|b=~e[:regex]}
          sub_builds = builds.select{|b|b=~e[:regex]}
          if sub_builds.size > 1
            sub_builds.each_with_index do |b,k|
              b =~ e[:build_name_regex]
              name = e[:compiler_name]
              version = $2
              if k == 0
                output << "  if "
              else
                output << "  } elseif "
              end
              output << "[ is-loaded #{name}/#{version} ] {\n"
              output << "    set BUILD #{b}\n"
              notice_info b.rjust(25) + "   #{e[:prg_env]} + #{name}/#{version}"
            end
            output << "  } else {\n"
            output << "    set BUILD #{sub_builds.last}\n"
            output << "  }\n"
          else
            output << "  set BUILD #{builds[j]}\n"
            notice_info builds[j].rjust(25) + "   #{e[:prg_env]}"
          end
        else
          output << "  puts stderr \"Not implemented for the #{e[:human_name]} compiler\"\n"
        end
      end

      output << "}\n"
      output << "if {![info exists BUILD]} {\n"
      output << "  puts stderr \"[module-info name] is only available for the following environments:\"\n"
      builds.each do |build|
        output << "  puts stderr \"#{build}\"\n"
      end
      output << "  break\n}\n"

      return output
    end

    def self.get_module_names(options = {})
      if options[:only]
        module_dirs = options[:only].split(':')
        raise "No module directories could be found" if module_dirs.empty?
      else
        raise "$MODULEPATH is not set" unless ENV.has_key?('MODULEPATH')
        module_dirs = ENV['MODULEPATH'].split(':')
        raise "$MODULEPATH is empty" if module_dirs.empty?
      end

      system_module_names = []
      system_module_defaults = []
      if options[:except]
        module_dirs.delete_if{|p| options[:except].split(":").include?(p)}
      end
      module_dirs.each do |p|
        module_files          = Dir.glob(p+"/*/*").sort
        module_files_defaults = module_files.dup
        version_files         = Dir.glob(p+"/*/.version").sort

        version_files.each do |version_file|
          module_name = File.basename(File.dirname(version_file))
          file_content = ""
          File.open(version_file).readlines.each { |line| file_content << line.chomp }

          if file_content =~ /ModulesVersion "(.*?)"/
            version = $1
            module_files_defaults.collect! do |m|
              if m =~ /#{module_name}\/#{version}$/
                m+"(default)"
              else
                m
              end
            end
          end

        end

        module_files.collect!{|s| s.gsub(p+"/", '')}
        system_module_names += module_files
        system_module_defaults += module_files_defaults
      end

			# desired_modules = %w{ ^cce ^pgi ^intel ^gcc ^hdf5 ^netcdf ^fftw ^petsc ^trilinos ^chapel ^java ^ntk ^papi ^stat ^gdb ^perftools ^tpsl ^ga\/ ^libsci_acc ^acml }
			# stub_packages = system_module_names.select{|m| m =~ /(#{desired_modules.join('|')})/}

      return system_module_names, system_module_defaults
    end

  end
end
