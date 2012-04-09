module Smithy
  class Package
    attr_accessor :arch, :root, :name, :version, :build_name
    attr_accessor :group

    def self.normalize_name(args = {})
      # Remove root and arch from the path if necessary
      p = args[:name].dup
      if args[:swroot]
        root = File.dirname args[:swroot]
        arch = File.basename args[:swroot]
      else
        root = args[:root]
        arch = args[:arch]
      end
      p.gsub! /\/?#{root}\/?/, ''
      p.gsub! /\/?#{arch}\/?/, ''
      return p
    end

    def initialize(args = {})
      @root = File.dirname args[:root]
      @arch = File.basename args[:root]
      @path = Package.normalize_name(:name => args[:path], :root => @root, :arch => @arch)
      @path =~ /(.*)\/(.*)\/(.*)$/
      @name = $1
      @version = $2
      @build_name = $3
      @group = args[:file_group]

      @group_writeable = true
      @group_writeable = false if args[:disable_group]
    end

    PackageFileNames = {
      :exception   => ".exceptions",
      :description => "description",
      :support     => "support",
      :versions    => "versions" }

    def package_support_files
      file_list = PackageFileNames.values
      file_list.collect! do |f|
        { :src  => File.join(@@smithy_bin_root, "etc/templates/package", f),
          :dest => File.join(application_directory, f) }
      end
      return file_list
    end

    BuildFileNames = {
      :notes        => "build-notes",
      :dependencies => "dependencies",
      :build        => "rebuild",
      :link         => "relink",
      :test         => "retest",
      :env          => "remodule" }
    ExecutableBuildFileNames = [
      BuildFileNames[:build],
      BuildFileNames[:link],
      BuildFileNames[:test],
      BuildFileNames[:env]
    ]

    def build_support_files
      file_list = BuildFileNames.values
      file_list.collect! do |f|
        { :src  => File.join(@@smithy_bin_root, "etc/templates/build", f),
          :dest => File.join(prefix, f) }
      end
      return file_list
    end

    def group_writeable?
      @group_writeable
    end

    def valid?
      # Name format validation
      if @name.nil? || @version.nil? || @build_name.nil? || @name.include?('/') || @version.include?('/') || @build_name.include?('/')
        raise "The package name \"#{@path}\" must be of the form: NAME/VERSION/BUILD"
        return false
      else
        return true
      end
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
      File.join(prefix,"remodule")
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
        notice_fail "#{lock_file} exists, is someone else building this package? If not delete and rerun."
        return false
      else
        FileUtils.touch(lock_file)
        return true
      end
    end

    def delete_lock_file
      FileUtils.rm_f(lock_file)
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

      ENV['SMITHY_PREFIX'] = prefix
      ENV['SW_BLDDIR'] = prefix

      unless args[:disable_logging]
        if args[:log_name]
          log_file_path = File.join(prefix, args[:log_name])
          log_file = File.open(log_file_path, 'w') unless args[:dry_run]

          FileOperations.set_group(log_file, group)
          FileOperations.make_group_writable(log_file) if group_writeable?
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
            process_ouput(stdout, stderr, args[:send_to_stdout], log_file)
            sleep 0.25
          end

          exit_status = t.exitstatus # this will throw an exception if != 0
        rescue => exception
          exit_status = exception.exitstatus
        end
        # There is usually some leftover output
        process_ouput(stdout, stderr, args[:send_to_stdout], log_file)

        log_file.close unless log_file.nil?

        if exit_status == 0
          notice_success "SUCCESS #{prefix}"
        else
          notice_fail "FAILED #{prefix}"
        end

        case args[:script]
        when :build
          if exit_status == 0
            notice "Setting permissions on installed files"
            FileOperations.set_group prefix, @group, :recursive => true
            FileOperations.make_group_writable prefix, :recursive => true if group_writeable?
          end
        when :test
        end

        delete_lock_file
      end
    end

    def extract(args = {})
      archive = args[:archive]
      temp_dir = File.join(prefix,"tmp")
      source_dir = File.join(prefix,"source")

      notice "Extracting #{archive} to #{source_dir}"

      return if args[:dry_run]

      overwrite = nil
      if File.exists?(source_dir)
        while overwrite.nil? do
          prompt = Readline.readline("Overwrite #{source_dir}? (enter \"h\" for help) [ynqh] ")
          case prompt.downcase
          when "y"
            overwrite = true
          when "n"
            overwrite = false
          when "h"
            puts %{y - yes, overwrite
  n - no, do not overwrite
  q - quit, abort
  h - help, show this help}
          when "q"
            raise "Abort new package"
          end
        end
      else
        overwrite = true
      end

      if overwrite
        FileUtils.rm_rf temp_dir
        FileUtils.rm_rf source_dir
        FileUtils.mkdir temp_dir
        FileUtils.cd temp_dir

        magic_bytes = nil
        File.open(archive) do |f|
          magic_bytes = f.read(4)
        end
        case magic_bytes
        when /^PK\003\004/ # .zip archive
          `unzip #{tarfile}`
        when /^\037\213/, /^BZh/, /^\037\235/  # gzip/bz2/compress compressed
          `tar xf #{archive}`
        end

        extracted_files = Dir.glob('*')
        if extracted_files.count == 1
          FileUtils.mv extracted_files.first, source_dir
        else
          FileUtils.cd prefix
          FileUtils.mv temp_dir, source_dir
        end

        FileUtils.rm_rf temp_dir

        FileOperations.set_group source_dir, @group, :recursive => true
        FileOperations.make_group_writable source_dir, :recursive => true if group_writeable?
      end
    end

    def create(args = {})
      notice "New #{prefix} #{args[:dry_run] ? "(dry run)" : ""}"
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      directories.each do |dir|
        FileOperations.make_directory dir, options
        FileOperations.set_group dir, group, options
        FileOperations.make_group_writable dir, options if group_writeable?
      end

      all_files = build_support_files
      all_files = package_support_files + all_files if args[:web]

      all_files.each do |file|
        FileOperations.install_file file[:src], file[:dest], options
        FileOperations.set_group file[:dest], group, options
        FileOperations.make_group_writable file[:dest], options if group_writeable?
        FileOperations.make_executable file[:dest], options if file[:dest] =~ /(#{ExecutableBuildFileNames.join('|')})/
      end
    end

    def repair(args = {})
      notice "Repair #{prefix} #{args[:dry_run] ? "(dry run)" : ""}"
      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]
      options[:verbose] = true if args[:dry_run] || args[:verbose]

      notice "Setting permissions"

      FileOperations.set_group prefix, group, options.merge(:recursive => true)
      FileOperations.make_group_writable prefix, options.merge(:recursive => true) if group_writeable?

      [version_directory, application_directory].each do |dir|
        FileOperations.set_group dir, group, options
        FileOperations.make_group_writable dir, options if group_writeable?
      end

      notice "Checking support files"
      (package_support_files+build_support_files).each do |file|
        f = file[:dest]

        if File.exists?(f)
          if File.size(f) == 0
            puts "empty ".rjust(12).color(:red) + f
          else
            puts "exists ".rjust(12).bright + f
          end
          FileOperations.make_executable file[:dest], options if f =~ /#{ExecutableBuildFileNames.join('|')}/
        else
          puts "missing ".rjust(12).bright + f
          # copy template?
        end
      end
    end

    def alternate_builds
      builds = Dir.glob(version_directory+"/*")
      # Delete anything that isn't a directory
      builds.reject! { |b| ! File.directory?(b) }
      builds.reject! { |b| b =~ /#{ModuleFile::PackageModulePathName}/ }
      # Get the directory name from the full path
      builds.collect! { |b| File.basename(b) }
      return builds.sort
    end

    def publishable?
      Description.publishable?(application_directory)
    end

    def self.all(args = {})
      # Array of full paths to rebuild scripts
      software = Dir.glob(args[:root]+"/*/*/*/#{BuildFileNames[:build]}")
      # Remove rebuild from each path
      software.collect!{|s| s.gsub(/\/#{BuildFileNames[:build]}$/, '')}
      #TODO allow sorting?
      software.sort!
    end

    def self.all_web(args = {})
      # Find all software with descriptions
      software = Dir.glob(args[:root]+"/*/#{PackageFileNames[:description]}")
      software.collect!{|s| s.gsub(/\/#{PackageFileNames[:description]}$/, '')}
      # Remove any with noweb in their exceptions file
      software.reject! do |s|
        ! Description.publishable?(s)
      end

      #software.collect! do |s|
        #builds = Dir.glob(s+"/*/*/rebuild")
        #builds.collect!{|s| s.gsub(/\/rebuild$/, '')}
        #builds.first
      #end
      #software.compact!

      return software
    end

  end
end
