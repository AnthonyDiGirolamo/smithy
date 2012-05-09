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
      notice "Creating Modulefile for #{package.prefix}"

      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]
      erb_file = File.join(@@smithy_bin_root, "/etc/templates/modulefile.erb")

      module_dir = File.join(module_path, package.name)
      FileUtils.mkdir_p(module_dir, options)

      new_module = module_file+"_#{Time.now.to_i}"
      old_module = module_file

      erb = ERB.new(File.read(erb_file), nil, "<>")
      File.open(new_module, "w+") do |f|
        f.write erb.result(get_binding)
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
      install_dir = File.join(system_module_path, package.name)
      FileOperations.make_directory install_dir
      FileOperations.install_file module_file, destination, options
      FileOperations.make_group_writable(install_dir, options.merge(:recursive => true))
      FileOperations.set_group(install_dir, package.group, options.merge(:recursive => true))
    end

    Environments = [
      {:prg_env => "PrgEnv-gnu",       :compiler_name => "gcc",       :human_name => "gnu",       :regex => /(gnu|gcc)(.*)/},
      {:prg_env => "PrgEnv-pgi",       :compiler_name => "pgi",       :human_name => "pgi",       :regex => /(pgi)(.*)/},
      {:prg_env => "PrgEnv-intel",     :compiler_name => "intel",     :human_name => "intel",     :regex => /(intel)(.*)/},
      {:prg_env => "PrgEnv-cray",      :compiler_name => "cce",       :human_name => "cray",      :regex => /(cce|cray)(.*)/},
      {:prg_env => "PrgEnv-pathscale", :compiler_name => "pathscale", :human_name => "pathscale", :regex => /(pathscale)(.*)/}
    ]

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
              b =~ e[:regex]
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

  end
end
