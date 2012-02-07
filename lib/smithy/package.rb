module Smithy
  class Package
    attr_accessor :arch, :root, :name, :version, :build_name
    attr_accessor :group

    def initialize(args = {})
      @root   = args[:root]
      @arch   = args[:arch]
      # Remove root and arch from the path if necessary
      @path = args[:path]
      path = args[:path].gsub(/\/?#{root}\/?/,'').gsub(/\/?#{arch}\/?/,'').gsub(/\/rebuild$/,'')
      path =~ /(.*)\/(.*)\/(.*)$/
      @name = $1
      @version = $2
      @build_name = $3
      @group = args[:file_group]

      if args[:disable_group]
        @group_writeable = false
      else
        @group_writeable = true
      end
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

    def rebuild_script_exists?
      File.exist?(rebuild_script)
    end
    def rebuild_script_exists!
      raise "The script #{rebuild_script} does not exist!" unless rebuild_script_exists?
    end

    def prefix
      File.join(@root, @arch, @name, @version, @build_name)
    end

    def rebuild_script
      File.join(prefix,"rebuild")
    end

    def software_root
      File.join(@root, @arch)
    end

    def prefix_exists?
      Dir.exist? prefix
    end
    def prefix_exists!
      raise "The package #{prefix} does not exist!" unless prefix_exists?
    end

    def run_rebuild_script(args ={})
      #TODO check for .lock file, create and delete after complete
      rebuild_script_exists!

      ENV['SMITHY_PREFIX'] = prefix
      ENV['SW_BLDDIR'] = prefix

      notice "Building #{prefix}"

      unless args[:disable_logging]
        if args[:build_log_name]
          log_file_path = File.join(prefix, args[:build_log_name])
          log_file = File.open(log_file_path, 'w') unless args[:dry_run]

          set_group(log_file, group)
          make_group_writable(log_file) if group_writeable?
        end
        if args[:dry_run] || log_file != nil
          notice "Logging to #{log_file_path}"
        end
      end

      unless args[:dry_run]
        stdout, stderr = '',''
        build_exit_status = 0

        begin
          t = Open4.background(rebuild_script, 0=>'', 1=>stdout, 2=>stderr)
          while t.status do
            process_ouput(stdout, stderr, args[:send_to_stdout], log_file)
            sleep 0.25
          end

          build_exit_status = t.exitstatus # this will throw an exception if != 0
        rescue => exception
          build_exit_status = exception.exitstatus
        end
        # There is usually some leftover output
        process_ouput(stdout, stderr, args[:send_to_stdout], log_file)

        log_file.close unless log_file.nil?

        set_group prefix, @group, :recursive => true
        make_group_writable prefix, :recursive => true if group_writeable?

        if build_exit_status == 0
          notice_success "#{prefix} SUCCESS"
        else
          notice_fail "#{prefix} FAILED"
        end
      end
    end

    def extract(args = {})
      archive = File.join(Dir.pwd, args[:archive])
      unless File.exists? archive
        raise "The archive #{archive} does not exist"
      end

      temp_dir = File.join(prefix,"tmp")
      source_dir = File.join(prefix,"source")
      FileUtils.rm_rf temp_dir
      FileUtils.rm_rf source_dir
      FileUtils.mkdir temp_dir
      FileUtils.cd temp_dir

      notice "Extracting #{archive} to #{source_dir}"

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

      #TODO set permissions on source dir
      set_group source_dir, @group, :recursive => true
      make_group_writable source_dir, :recursive => true if group_writeable?
    end

    def create(args = {})
      notice "New #{prefix}"

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
        set_group d, group, options
        make_group_writable d, options if group_writeable?
      end

      if args[:web]
        all_files = package_files+build_files
      else
        all_files = build_files
      end

      all_files.each do |f|
        install_file f[:src], f[:dest], options
        set_group f[:dest], group, options
        make_group_writable f[:dest], options if group_writeable?

        make_executable f[:dest], options if f[:dest] =~ /(rebuild|relink|retest)/
      end
    end
  end
end
