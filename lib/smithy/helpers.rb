# try and blank? methods borrowed from rails
# See: https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/try.rb
class Object
  def try(method, *args, &block)
    send(method, *args, &block)
  end
  remove_method :try
  alias_method :try, :__send__

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class NilClass #:nodoc:
  def try(*args)
    nil
  end

  def blank?
    true
  end
end

module Smithy
  def notice(message)
    STDOUT.puts ("==> "+message).bright if STDOUT.tty?
  end

  def notice_warn(message)
    STDOUT.puts ("==> "+message).color(:yellow) if STDOUT.tty?
  end

  def notice_info(message)
    STDOUT.puts (message).color(:blue) if STDOUT.tty?
  end

  def notice_command(command, comment, width=40)
    STDOUT.puts command.bright.ljust(width)+comment.color(:blue) if STDOUT.tty?
  end

  def notice_success(message)
    if STDOUT.tty?
      STDOUT.puts ("==> "+message).color(:green)
    else
      STDOUT.puts message
    end
  end

  def notice_fail(message)
    if STDOUT.tty?
      STDOUT.puts ("==> "+message).color(:red)
    else
      STDOUT.puts message
    end
  end

  def process_ouput(stdout, stderr, suppress_stdout = false, log_file = nil)
    unless stdout.empty?
      puts stdout unless suppress_stdout
      log_file.puts stdout unless log_file.nil?
      stdout.replace("")
    end
    unless stderr.empty?
      puts stderr unless suppress_stdout
      log_file.puts stderr unless log_file.nil?
      stderr.replace("")
    end
  end

  def system_config_file(global = {})
    if global[:"config-file"]
      sysconfig_path = File.expand_path(global[:"config-file"])
    elsif ENV['SMITHY_CONFIG']
      sysconfig_path = File.expand_path(ENV['SMITHY_CONFIG'])
    else
      sysconfig_path = File.expand_path(@smithy_config_file)
    end

    if File.exists? sysconfig_path
      @smithy_config_file = sysconfig_path
      @smithy_config_hash = YAML.load_file(sysconfig_path)
      return @smithy_config_hash
    else
      return nil
    end
  end

  def architectures
    @smithy_config_hash['hostname-architectures'].values.uniq
  end

  def load_system_config(global = {})
    options = {}
    @smithy_config_hash = system_config_file(global)
    if @smithy_config_hash
      options[:"software-root"]   = @smithy_config_hash.try(:[], "software-root")
      options[:"web-root"]        = @smithy_config_hash.try(:[], "web-root")
      options[:"file-group-name"] = @smithy_config_hash.try(:[], "file-group-name")
      if options[:"file-group-name"]
        options[:"file-group-id"]   = Etc.getgrnam(options[:"file-group-name"]).try(:gid)
      end

      options[:arch] = global[:arch] || get_arch
      options[:full_software_root_path] = get_software_root(
        :root => options[:"software-root"],
        :arch => options[:arch])
    else
      STDERR.puts "warning: Cannot read config file: #{@smithy_config_file}"
    end

    return options
  end

  def get_arch
    @hostname = ENV['HOSTNAME'].chomp || `hostname -s`.chomp
    # Remove trailing numbers (if they exist) and a possible single trailing period
    machine = @hostname.gsub(/(\d*)\.?$/,'')
    arch = @smithy_config_hash.try(:[], "hostname-architectures").try(:[], machine)
    # Match against hostname if previous attempt fails
    arch = @smithy_config_hash.try(:[], "hostname-architectures").try(:[], @hostname) if arch.nil?
    #TODO Check for nil arch and print coherent error message
    return arch
  end

  def get_software_root(args = {})
    if args[:root].blank? || args[:arch].blank?
      raise """Cannot determine which architecture we are using.
       Please specify using --arch or add a '#{@hostname}' hostname entry to:
       #{@smithy_config_file}"""
    end

    swroot = File.join(args[:root], args[:arch])
    raise "The software-root directory '#{swroot}' is not valid" unless Dir.exist?(swroot)
    return swroot
  end

  def last_prefix
    rc_file = File.join(ENV['HOME'], '.smithyrc')
    if File.exists?(rc_file)
      h = YAML.load_file(rc_file) rescue nil
      return h[:last]
    else
      return nil
    end
  end

  def save_last_prefix(prefix)
    rc_file = File.join(ENV['HOME'], '.smithyrc')
    h = {:last => prefix}
    File.open(rc_file, "w+") do |f|
      f.write(h.to_yaml)
    end
  end

end
