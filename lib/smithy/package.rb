module Smithy
  class Package
    attr_accessor :arch, :root, :name, :version, :build_name

    def initialize(args = {})
      @root   = args[:root]
      @arch   = args[:arch]
      # Remove root and arch from the path if necessary
      path = args[:path].gsub(/\/?#{root}\/?/,'').gsub(/\/?#{arch}\/?/,'').gsub(/\/rebuild$/,'')
      path =~ /(.*)\/(.*)\/(.*)$/
      @name = $1
      @version = $2
      @build_name = $3
    end

    def valid?
      # Name format validation
      if name.nil? || version.nil? || build_name.nil?
        raise "Package names must be of the form: NAME/VERSION/BUILD"
      end
      if name.include?('/') || version.include?('/') || build_name.include?('/')
        raise "Package names must be of the form: NAME/VERSION/BUILD"
      end
      return true
    end

    def prefix
      File.join(@root, @arch, @name, @version, @build_name)
    end

    def software_root
      File.join(@root, @arch)
    end

    def prefix_exists?
      Dir.exist? prefix
    end

    def run_rebuild_script(args ={})
      #TODO check for .lock file, create and delete after complete

      rebuild_script = File.join(prefix,"rebuild")
      raise "Cannot locate rebuild script #{rebuild_script}" unless File.exist? rebuild_script
      ENV['SMITHY_PREFIX'] = prefix
      ENV['SW_BLDDIR'] = prefix

      notice "Building #{prefix}"

      unless args[:disable_logging]
        if args[:build_log_name]
          log_file_path = File.join(prefix, args[:build_log_name])
          log_file = File.open(log_file_path, 'w') unless args[:dry_run]

          log_file.chmod(log_file.stat.mode | args[:file_mask])
          log_file.chown(nil, args[:file_group])
        end
        if args[:dry_run] || log_file != nil
          notice "Logging to #{log_file_path}"
        end
      end

      unless args[:dry_run]
        stdout, stderr = '',''
        t = Open4.background(rebuild_script, 0=>'', 1=>stdout, 2=>stderr)
        while t.status do
          process_ouput(stdout, stderr, args[:send_to_stdout], log_file)
          sleep 0.25
        end

        build_exit_status = t.exitstatus
        process_ouput(stdout, stderr, args[:send_to_stdout], log_file)

        log_file.close unless log_file.nil?

        if build_exit_status == 0
          notice_success "#{prefix} SUCCESS"
        else
          notice_fail "#{prefix} FAILED"
        end
      end
    end

    def create(args = {})
      directories = [
        File.join(software_root, name),
        File.join(software_root, name, version),
        File.join(software_root, name, version, build_name) ]

      package_files = %w{.exceptions description support versions}
      package_files.collect! do |f|
        { :src  => File.join(args[:smithy_root], "etc/templates/package", f),
          :dest => File.join(directories.first, f) }
      end

      build_files = %w{build-notes dependencies rebuild relink remodule retest}
      build_files.collect! do |f|
        { :src  => File.join(args[:smithy_root], "etc/templates/build", f),
          :dest => File.join(directories.last, f) }
      end

      options = {:noop => false, :verbose => false}
      options[:noop] = true if args[:dry_run]

      directories.each do |d|
        make_directory d, options
        set_permissions d, args[:file_group], args[:file_mask], options
      end

      (package_files+build_files).each do |f|
        install_file f[:src], f[:dest], options
        set_permissions f[:dest], args[:file_group], args[:file_mask], options
      end
    end
  end
end
