# Smithy is freely available under the terms of the BSD license given below. {{{
#
# Copyright (c) 2012. UT-BATTELLE, LLC. All rights reserved.
#
# Produced by the National Center for Computational Sciences at Oak Ridge
# National Laboratory. Smithy is a based on SWTools, more information on SWTools
# can be found at: http://www.olcf.ornl.gov/center-projects/swtools/
#
# This product includes software produced by UT-Battelle, LLC under Contract No.
# DE-AC05-00OR22725 with the Department of Energy.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# - Neither the name of the UT-BATTELLE nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# }}}

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

    def self.compilers
      Smithy::Config.compilers || Environments
    end

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

      if args[:existing]
        existing_modulefile = File.join(args[:existing], "../modulefile", package.name, package.version)
        FileOperations.install_file(existing_modulefile, module_file, options) if File.exists?(existing_modulefile)
      else
        FileOperations.render_erb :destination => module_file,
          :erb => File.join(Smithy::Config.bin_root, "/etc/templates/modulefile.erb"),
          :binding => get_binding, :options => options
      end

      FileOperations.make_group_writable(module_path, options.merge(:recursive => true))
      FileOperations.set_group(module_path, package.group, options.merge(:recursive => true))
    end

    def deploy(args = {})
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      g = system_module_path+"/*#{package.name}*/*#{package.version}*"
      module_matches = Dir.glob(g)
      module_matches.sort!
      if module_matches.size > 1
        notice_warn "Warning - multiple existing modulefiles found:"
        module_matches.each_with_index do |m,i|
          puts [i+1, m].join(': ')
        end

        selected_modulefile = "unknown"
        while selected_modulefile == "unknown" do
          prompt = Readline.readline("Select a modulefile to deploy to (\"h\" for help \"q\" quits) [1] ")
          response = prompt.downcase
          case response
          when /^[1-9]$/
            selected_modulefile = response.to_i - 1
          when "h"
            indent = "  "
            puts indent+"1-9   - select a modulefile"
            puts indent+"ENTER - select modulefile 1"
            puts indent+"q     - abort module deploy"
            puts indent+"h     - help, show this help"
          when "q"
            raise "Abort module deploy"
          else
            selected_modulefile = 0
          end
        end
      end

      if module_matches.empty?
        destination = system_module_file
      elsif selected_modulefile.present?
        destination = module_matches[selected_modulefile]
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

    def python_module_build_list(package, builds, args = {})
      package.build_name
      valid_builds = Hash[builds.select{|b| b.include?("python")}.collect{|b| [get_python_version_from_build_name(b), b]}.select{|b| module_is_available?(b.first)}]

      output = [ "if [ is-loaded " ]

      valid_builds.each do |modulefile, buildname|
        output.last << modulefile + " ] {\n"
        output.last << "  set BUILD " + buildname + "\n"
        output.last << "  set LIBDIR " + python_libdir(get_python_version_from_build_name(buildname)) + "\n"
        output << ""
      end

      output.reject!(&:blank?)

      output.last << "}\n"

      output.join("} elseif [ is-loaded ")
    end

    def module_build_list(package, builds, args = {})
      output = ""

      notice "Multiple Builds Found" if Smithy::Config.global[:verbose]
      notice_info "Build Name".rjust(25)+"   Required Modules" if Smithy::Config.global[:verbose]
      ModuleFile::compilers.each_with_index do |e,i|

        prgenv =  e[:prg_env]
        prgenv.gsub!(/PrgEnv-/, args.fetch(:prgenv_prefix)) if args[:prgenv_prefix]

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
              notice_info b.rjust(25) + "   #{e[:prg_env]} + #{name}/#{version}" if Smithy::Config.global[:verbose]
            end
            output << "  } else {\n"
            output << "    set BUILD #{sub_builds.last}\n"
            output << "  }\n"
          else
            output << "  set BUILD #{builds[j]}\n"
            notice_info builds[j].rjust(25) + "   #{e[:prg_env]}" if Smithy::Config.global[:verbose]
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
