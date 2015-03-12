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
  class Package
    attr_accessor :arch, :root, :name, :version, :build_name
    attr_accessor :group

    def self.normalize_name(name)
      name = Dir.pwd if name == "."
      name_split = name.split('/')
      name_version_build = []
      name_version_build << name_split[-3]
      name_version_build << name_split[-2]
      name_version_build << name_split[-1]
      name_version_build.compact!
      return File.join(name_version_build)
    end

    def initialize(args = {})
      @root = File.dirname(Smithy::Config.full_root)
      @arch = File.basename(Smithy::Config.full_root)

      if args[:path].try(:downcase) == 'last'
        @path = Smithy::Config.last_prefix
      else
        @path = Package.normalize_name(args[:path])
      end
      @path =~ /(.*)\/(.*)\/(.*)$/
      @name = $1
      @version = $2
      @build_name = $3
      @group = Smithy::Config.file_group

      @group_writable = Smithy::Config.group_writable?
      @group_writable = args[:group_writable] if args.has_key?(:group_writable)
    end

    def get_binding
      binding
    end

    PackageFileNames = {
      :exception   => ".exceptions",
      :description => "description.markdown",
      :support     => "support",
      :versions    => "versions" }

    def package_support_files
      file_list = []
      PackageFileNames.each do |name, file|
        file_list << { :name => name,
          :src  => File.join(Smithy::Config.bin_root, "etc/templates/package", file),
          :dest => File.join(application_directory, file) }
      end
      return file_list
    end

    BuildFileNames = {
      :notes        => "build-notes",
      :dependencies => "dependencies",
      :build        => "rebuild",
      :test         => "retest",
      :env          => "remodule" }
    ExecutableBuildFileNames = [
      BuildFileNames[:build],
      BuildFileNames[:link],
      BuildFileNames[:test],
      BuildFileNames[:env]
    ]
    BuildFileERBs = [
      BuildFileNames[:env] ]

    def build_support_files(alternate_source)
      file_list = []
      BuildFileNames.each do |name, file|
        src = File.join(Smithy::Config.bin_root, "etc/templates/build", file)
        src += ".erb" if BuildFileERBs.include?(file)

        if alternate_source && Dir.exists?(alternate_source)
          alt_src = File.join(alternate_source, file)
          src     = alt_src if File.exists? alt_src
        end

        file_list << { :name => name, :src => src, :dest => File.join(prefix, file) }
      end
      return file_list
    end

    def group_writable?
      @group_writable
    end

    def valid?
      # Name format validation
      if @name.nil? || @version.nil? || @build_name.nil? || @name.include?('/') || @version.include?('/') || @build_name.include?('/')
        raise "The package name \"#{@path}\" must be of the form: NAME/VERSION/BUILD"
        return false
      end

      # If good, save as last prefix
      Smithy::Config.save_last_prefix(qualified_name)
      return true
    end

    def qualified_name
      [@name, @version, @build_name].join('/')
    end

    def prefix
      File.join(@root, @arch, @name, @version, @build_name)
    end
    def prefix_exists?
      Dir.exist? prefix
    end
    def prefix_exists!
      raise "The package #{prefix} does not exist!" unless prefix_exists?
    end

    def source_directory
      File.join(prefix,"source")
    end

    def rebuild_script
      File.join(prefix, BuildFileNames[:build])
    end
    def rebuild_script_exists?
      File.exist?(rebuild_script)
    end
    def rebuild_script_exists!
      raise "The script #{rebuild_script} does not exist!" unless rebuild_script_exists?
    end

    def retest_script
      File.join(prefix, BuildFileNames[:test])
    end
    def retest_script_exists?
      File.exist?(retest_script)
    end
    def retest_script_exists!
      raise "The script #{retest_script} does not exist!" unless retest_script_exists?
    end

    def remodule_script
      File.join(prefix, BuildFileNames[:env])
    end
    def remodule_script_exists?
      File.exist?(remodule_script)
    end
    def remodule_script_exists!
      raise "The script #{remodule_script} does not exist!" unless remodule_script_exists?
    end

    def application_directory
      File.join(@root, @arch, @name)
    end

    def version_directory
      File.join(@root, @arch, @name, @version)
    end

    def directories
      [ application_directory, version_directory, prefix ]
    end

    def software_root
      File.join(@root, @arch)
    end

    def lock_file
      File.join(prefix, ".lock")
    end

    def create_lock_file
      if File.exists? lock_file
        notice_fail "#{lock_file} exists, is someone else building this package? If not, use --force or delete and rerun."
        return false
      else
        FileUtils.touch(lock_file)
        FileOperations.set_group(lock_file, group)
        FileOperations.make_group_writable(lock_file) if group_writable?
        return true
      end
    end

    def delete_lock_file
      FileUtils.rm_f(lock_file)
    end

    def valid_build_file
      File.join(prefix, ".valid")
    end

    def create_valid_build_file
      unless File.exists? valid_build_file
        FileUtils.touch(valid_build_file)
        FileOperations.set_group(valid_build_file, group)
        FileOperations.make_group_writable(valid_build_file) if group_writable?
        return true
      end
    end

    def delete_valid_build_file
      FileUtils.rm_f(valid_build_file)
    end

    def run_script(args ={})
      case args[:script]
      when :build
        rebuild_script_exists!
        script = rebuild_script
        notice "Building #{prefix}"
      when :test
        retest_script_exists!
        script = retest_script
        notice "Testing #{prefix}"
      else
        return nil
      end

      notice_warn "Dry Run! (scripts will not run)" if args[:dry_run]

      ENV['SMITHY_PREFIX'] = prefix
      ENV['SW_BLDDIR'] = prefix

      unless args[:disable_logging]
        if args[:log_name]
          log_file_path = File.join(prefix, args[:log_name])
          log_file = File.open(log_file_path, 'w') unless args[:dry_run]

          FileOperations.set_group(log_file, group)
          FileOperations.make_group_writable(log_file) if group_writable?
        end
        if args[:dry_run] || log_file != nil
          notice "Logging to #{log_file_path}"
        end
      end

      unless args[:dry_run]
        if args[:force]
          delete_lock_file
          create_lock_file
        else
          return unless create_lock_file
        end

        stdout, stderr = '',''
        exit_status = 0

        begin
          t = Open4.background(script, 0=>'', 1=>stdout, 2=>stderr)
          while t.status do
            process_ouput(stdout, stderr, args[:suppress_stdout], log_file)
            sleep 0.25
          end

          exit_status = t.exitstatus # this will throw an exception if != 0
        rescue => exception
          exit_status = exception.exitstatus
        end
        # There is usually some leftover output
        process_ouput(stdout, stderr, args[:suppress_stdout], log_file)

        log_file.close unless log_file.nil?

        if exit_status == 0
          notice_success "SUCCESS #{prefix}"
        else
          notice_fail "FAILED #{prefix}"
        end

        case args[:script]
        when :build
          set_file_permissions_recursive if exit_status == 0
        when :test
        end

        delete_lock_file
      end
    end

    def set_file_permissions_recursive
      if group_writable?
        notice "Setting permissions on installed files"
        FileOperations.set_group prefix, @group, :recursive => true
        FileOperations.make_group_writable prefix, :recursive => true if group_writable?
      end
    end

    def extract(args = {})
      archive = args[:archive]
      temp_dir = File.join(prefix,"tmp")

      notice "Extracting to #{source_directory}"

      return if args[:dry_run]

      overwrite = Smithy::Config.global.try(:[], :force) ? true : "unknown"
      overwrite = true if args[:overwrite]
      if File.exists?(source_directory)
        while overwrite == "unknown" do
          prompt = Readline.readline(" "*FILE_NOTICE_COLUMNS+"Overwrite? (enter \"h\" for help) [ynh] ")
          case prompt.downcase
          when "y"
            overwrite = true
          when "n"
            overwrite = false
          when "h"
            indent = " "*FILE_NOTICE_COLUMNS
            puts indent+"y - yes, delete existing folder and re-extract"
            puts indent+"n - no, do not overwrite"
            puts indent+"h - help, show this help"
          when "q"
            raise "Abort new package"
          end
        end
      else
        overwrite = true
      end

      if overwrite
        FileUtils.rm_rf temp_dir
        FileUtils.rm_rf source_directory
        FileUtils.mkdir temp_dir
        FileUtils.cd temp_dir

        magic_bytes = nil
        File.open(archive) do |f|
          magic_bytes = f.read(4)
        end
        case magic_bytes
        when /^PK\003\004/ # .zip archive
          `unzip #{archive}`
        else
          `tar xf #{archive}`
        end

        extracted_files = Dir.glob('*')
        if extracted_files.count == 1
          FileUtils.mv extracted_files.first, source_directory
        else
          FileUtils.cd prefix
          FileUtils.mv temp_dir, source_directory
        end

        FileUtils.rm_rf temp_dir

        FileOperations.set_group source_directory, @group, :recursive => true
        FileOperations.make_group_writable source_directory, :recursive => true if group_writable?
      end
    end

    def update_version_table_file(options)
      version_table_file = File.join(application_directory, ".versions")
      version_table = YAML.load_file(version_table_file).stringify_keys rescue {}
      if version_table[version].is_a? String
        version_table[version] = [ build_name.encode('UTF-8') ]
      elsif version_table[version].is_a? Array
        version_table[version] << build_name.encode('UTF-8') unless version_table[version].include?(build_name.encode('UTF-8'))
      else
        version_table.merge!({version.encode('UTF-8') => build_name.encode('UTF-8')})
      end

      FileOperations.install_from_string version_table.to_yaml, version_table_file, options.merge({:force => true})
      FileOperations.set_group version_table_file, group, options
      FileOperations.make_group_writable version_table_file, options if group_writable?
    end

    def create(args = {})
      notice "New #{args[:stub] ? "stub " : ""}#{prefix}"
      notice_warn "Dry Run! (no files will be created or changed)" if args[:dry_run]
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      if args[:stub]
        [application_directory].each do |dir|
          FileOperations.make_directory dir, options
          FileOperations.set_group dir, group, options
          FileOperations.make_group_writable dir, options if group_writable?
        end

        update_version_table_file(options)
      else

        directories.each do |dir|
          #if dir == prefix
            FileOperations.make_directory dir, options
            FileOperations.set_group dir, group, options
            FileOperations.make_group_writable dir, options if group_writable?
          #end
        end

        if args[:formula]
          update_version_table_file(options)
          return
        end

        all_files = build_support_files(args[:existing])
        all_files = package_support_files + all_files if args[:web] || args[:stub]

        all_files.each do |file|
          if file[:src] =~ /\.erb$/
            FileOperations.render_erb :erb => file[:src], :binding => get_binding, :options => options, :destination => file[:dest]
          elsif file[:name] == :description
            d = Description.new(:package => self)
            original_dest = file[:dest]
            file[:dest] = d.description_file_path
            FileOperations.make_directory(d.path, options) if d.global_description
            FileOperations.install_file(file[:src], file[:dest], options)
            FileOperations.make_symlink(file[:dest], original_dest, options) if d.global_description
          else
            FileOperations.install_file file[:src], file[:dest], options
          end

          FileOperations.set_group file[:dest], group, options
          FileOperations.make_group_writable file[:dest], options if group_writable?
          FileOperations.make_executable file[:dest], options if file[:dest] =~ /(#{ExecutableBuildFileNames.join('|')})/
        end

      end
    end

    def module_load_prgenv
      output = ""
      ModuleFile::compilers.each do |e|
        if build_name =~ e[:regex]
          output = "module load #{e[:prg_env]}"
          break
        end
      end
      return output
    end

    def repair(args = {})
      notice "Repair #{prefix} #{args[:dry_run] ? "(dry run)" : ""}"
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]
      options[:verbose] = true if args[:dry_run] || args[:verbose]

      missing_package   = []
      missing_build = []

      notice "Checking support files"
      (package_support_files+build_support_files).each do |file|
        f = file[:dest]

        if File.exists?(f)
          if File.size(f) == 0
            puts "empty ".rjust(12).color(:yellow) + f
          else
            puts "exists ".rjust(12) + f
          end
          FileOperations.make_executable file[:dest], options if f =~ /#{ExecutableBuildFileNames.join('|')}/
        else
          puts "missing ".rjust(12).color(:red) + f

          missing_package << File.basename(f) if PackageFileNames.values.include?(File.basename(f))
          missing_build << File.basename(f) if BuildFileNames.values.include?(File.basename(f))
        end
      end

      notice "Creating missing files" if !missing_package.empty? || !missing_build.empty?

      if !missing_package.empty?
        package_support_files.each do |file|
          if missing_package.include?(file[:name])
            FileOperations.install_file file[:src], file[:dest], options
            FileOperations.set_group file[:dest], group, options
            FileOperations.make_group_writable file[:dest], options if group_writable?
          end
        end
      end

      if !missing_build.empty?
        build_support_files.each do |file|
          if missing_build.include?(file[:name])
            FileOperations.install_file file[:src], file[:dest], options
            FileOperations.set_group file[:dest], group, options
            FileOperations.make_group_writable file[:dest], options if group_writable?
          end
        end
      end

      notice "Setting permissions for #{prefix}"

      FileOperations.set_group prefix, group, options.merge(:recursive => true)
      FileOperations.make_group_writable prefix, options.merge(:recursive => true) if group_writable?

      [version_directory, application_directory].each do |dir|
        FileOperations.set_group dir, group, options
        FileOperations.make_group_writable dir, options if group_writable?
      end
    end

    def alternate_builds
      Package.alternate_builds(self.version_directory)
    end

    def self.alternate_builds(version_directory)
      version = File.basename(version_directory)
      builds = Dir.glob(version_directory+"/*")
      # Delete anything that isn't a directory
      builds.reject! { |b| ! File.directory?(b) }
      builds.reject! { |b| b =~ /#{ModuleFile::PackageModulePathName}/ }
      # Get the directory name from the full path
      builds.collect! { |b| File.basename(b) }

      stubbed_builds = YAML.load_file(File.join(File.dirname(version_directory), ".versions")).stringify_keys rescue {}
      if stubbed_builds[version]
        if stubbed_builds[version].is_a? String
          builds += [ stubbed_builds[version] ]
        else
          builds += stubbed_builds[version]
        end
      end
      builds.uniq!

      return builds.sort
    end

    def alternate_versions
      Package.alternate_builds(self.application_directory)
    end

    def self.alternate_versions(application_directory)
      versions = Dir.glob(application_directory+"/*")
      # Delete anything that isn't a directory
      versions.reject! { |b| ! File.directory?(b) }
      # Get the directory name from the full path
      versions.collect! { |b| File.basename(b) }

      stubbed_builds = YAML.load_file(File.join(application_directory, ".versions")).stringify_keys rescue {}
      versions += stubbed_builds.keys
      versions.uniq!

      return versions.sort
    end

    def publishable?
      Description.publishable?(application_directory)
    end

    def self.search(query = '')
      Package.all.select{|s| s =~ /#{query}/}
    end

    def self.search_by_name(name)
      Package.all(:name => name)
    end

    def self.all(args = {})
      name    = args[:name]    || '*'
      version = args[:version] || '*'
      build   = args[:build]   || '*'
      # Array of full paths to rebuild scripts
      software =  Dir.glob(Smithy::Config.full_root+"/#{name}/#{version}/#{build}/#{BuildFileNames[:build]}")
      software += Dir.glob(Smithy::Config.full_root+"/#{name}/#{version}/#{build}/.valid")
      # Remove rebuild from each path
      software.collect!{|s| s.gsub(/\/(#{BuildFileNames[:build]}|\.valid)$/, '')}
      software.sort!
    end

    def self.all_web(args = {})
      # Find all software with descriptions
      descriptions_dir = Smithy::Config.full_root
      descriptions_dir = Smithy::Config.descriptions_root if Smithy::Config.descriptions_root
      software = Dir.glob(descriptions_dir+"/*/description*")

      software.collect!{|s| File.dirname(s) }
      software.uniq!

      # Remove any with noweb in their exceptions file
      software.reject! do |s|
        ! Description.publishable?(s)
      end
      software.sort!
      return software
    end

    def self.create_stubs_from_modules(stub_packages, system_module_defaults, options = {})
      notice "Generating stubs for the following modules:"
      Format.print_column_list(stub_packages)
      proceed = "no"
      while proceed == "no" do
        prompt = Readline.readline("Generate the above packages? [yn] ")
        case prompt.downcase
        when "y"
          proceed = true
        when "n"
          proceed = false
        end
      end

      raise "aborting package generation" if proceed == false

      stub_packages.each do |module_name|
        name, version = module_name.split("/")
        p = Package.new :path => "#{name}/#{version}/universal"
        p.create :stub => true, :dry_run => options[:"dry-run"]

        default_module = ""
        possible_defaults = system_module_defaults.select{ |m| m =~ %r{\/#{name}\/} }
        defaulted = possible_defaults.select{ |m| m =~ %r{\(default\)$} }
        if defaulted.size > 0
          default_module = defaulted.first
        else
          default_module = possible_defaults.last
        end

        help_content = modulehelp(name)
        #help_content.gsub!(/^[\t ]+/, '')
        help_content.gsub!(/^--* Module Specific Help.*-$/, '')
        help_content.gsub!(/^===================================================================$/, '')
        help_content.gsub!(/\A\n*/, '')
        help_content = """# #{name}

Categories:

## Description

The following information is available by running `module help #{name}`

~~~~~~~~~~~~~~~~~~~~~
#{help_content}
~~~~~~~~~~~~~~~~~~~~~
"""

        help_dest = File.join(p.application_directory, "description.markdown")

        ops = {:noop => options[:"dry-run"] ? true : false}
        FileOperations.install_from_string(help_content, help_dest, ops)
        FileOperations.set_group help_dest, p.group, ops
        FileOperations.make_group_writable help_dest, ops if p.group_writable?
      end
    end

  end
end
