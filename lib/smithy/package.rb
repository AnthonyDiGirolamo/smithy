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

          set_group(log_file, args[:file_group])
          make_group_writable(log_file, args[:file_mask]) unless args[:disable_group]
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

    def extract(args = {})
      archive = args[:archive]
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

      magic_bytes = ''
      File.open(archive) { |f| magic_bytes = f.read(4) }
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

      #if @tarball_path.extname == '.jar'
        #magic_bytes = nil
      #elsif @tarball_path.extname == '.pkg'
        ## Use more than 4 characters to not clash with magicbytes
        #magic_bytes = "____pkg"
      #else
        ## get the first four bytes
        #File.open(@tarball_path) { |f| magic_bytes = f.read(4) }
      #end

      ## magic numbers stolen from /usr/share/file/magic/
      #case magic_bytes
      #when /^PK\003\004/ # .zip archive
        #quiet_safe_system SystemCommand.unzip, {:quiet_flag => '-qq'}, @tarball_path
        #chdir
      #when /^\037\213/, /^BZh/, /^\037\235/  # gzip/bz2/compress compressed
        ## TODO check if it's really a tar archive
        #safe_system SystemCommand.tar, 'xf', @tarball_path
        #chdir
      #when '____pkg'
        #safe_system SystemCommand.pkgutil, '--expand', @tarball_path, File.basename(@url)
        #chdir
      #when 'Rar!'
        #quiet_safe_system 'unrar', 'x', {:quiet_flag => '-inul'}, @tarball_path
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
        set_group d, args[:file_group], options
        make_group_writable d, args[:file_mask], options unless args[:disable_group]
      end

      if args[:web]
        all_files = package_files+build_files
      else
        all_files = build_files
      end

      all_files.each do |f|
        install_file f[:src], f[:dest], options
        set_group f[:dest], args[:file_group], options
        make_group_writable f[:dest], args[:file_mask], options unless args[:disable_group]

        make_executable f[:dest] if f[:dest] =~ /(rebuild|relink|retest)/
      end
    end
  end
end
