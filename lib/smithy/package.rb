module Smithy
  class Package
    attr_accessor :arch, :root, :name, :version, :build_name

    def initialize(args = {})
      @root   = args[:root]
      @arch   = args[:arch]
      # Remove root and arch from the path if necessary
      path = args[:path].gsub(/#{root}\/?/,'').gsub(/\/?#{arch}\/?/,'').gsub(/\/rebuild$/,'')
      path =~ /(.*)\/(.*)\/(.*)$/
      @name = $1
      @version = $2
      @build_name = $3
    end

    def valid?
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

    def prefix_exists?
      Dir.exist? prefix
    end

    def run_rebuild_script(args ={})
      #TODO check for .lock file, create and delete after complete

      rebuild_script = File.join(prefix,"rebuild")
      raise "Cannot locate rebuild script #{rebuild_script}" unless File.exist? rebuild_script
      ENV['SW_BLDDIR'] = prefix

      notice "Building #{prefix}"

      unless args[:disable_logging]
        if args[:build_log_name]
          log_file_path = File.join(prefix, args[:build_log_name])
          log_file = File.open(log_file_path, 'w') unless args[:dry_run]

          # TODO set permissions based on config file
          log_file.chmod(log_file.stat.mode | 020)
          log_file.chown(nil, 1099)
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
  end
end
