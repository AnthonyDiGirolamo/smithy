# Borrowed from Rails
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/try.rb
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
    STDOUT.puts "==> "+message.bright if STDOUT.tty?
  end

  def notice_success(message)
    if STDOUT.tty?
      STDOUT.puts "==> "+message.color(:green)
    else
      STDOUT.puts message
    end
  end

  def notice_fail(message)
    if STDOUT.tty?
      STDOUT.puts "==> "+message.color(:red)
    else
      STDOUT.puts message
    end
  end

  def process_ouput(stdout, stderr, print_stdout = false, log_file = nil)
    unless stdout.empty?
      puts stdout if print_stdout
      log_file.puts stdout unless log_file.nil?
      stdout.replace("")
    end
    unless stderr.empty?
      puts stderr if print_stdout
      log_file.puts stderr unless log_file.nil?
      stderr.replace("")
    end
  end

  def load_system_config(global = {})
    if global[:"config-file"]
      sysconfig_path = File.expand_path(global[:"config-file"])
    else
      sysconfig_path = File.expand_path(@smithy_config_file)
    end

    options = {}

    if File.exists? sysconfig_path
      @smithy_config_hash = YAML.load_file(sysconfig_path)

      options[:"software-root"]   = @smithy_config_hash.try(:[], "software-root")
      options[:"file-group-name"] = @smithy_config_hash.try(:[], "file-group-name")
      if options[:"file-group-name"]
        options[:"file-group-id"]   = Etc.getgrnam(options[:"file-group-name"]).try(:gid)
      end

      options[:arch] = global[:arch] || get_arch
      options[:full_software_root_path] = get_software_root(
        :root => options[:"software-root"],
        :arch => options[:arch])
    else
      STDERR.puts "warning: Cannot read config file: #{sysconfig_path}"
    end

    return options
  end

  def get_arch
    @hostname = ENV['HOSTNAME'] || `hostname`.chomp
		machine = @hostname.gsub(/(\d*)$/,'')
		arch = @smithy_config_hash.try(:[], "hostname-architectures").try(:[], machine)
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

  def make_executable(f, options = {})
    p = File.stat(f).mode | 0111
    FileUtils.chmod p, f, options
  end

  def set_group(f, group, options = {})
    method = :chown
    if options.has_key? :recursive
      options.reject!{|k,v| k.eql?(:recursive)}
      method = :chown_R
    end
    FileUtils.send method, nil, group, f, options
  end

  def make_group_writable(f, options = {})
    f = f.path if f.class == File
    # FileUtils.chmod_R doesn't work well for combinations of files
    # with different bitmasks, it sets everything the same
    if options.has_key? :recursive
      `chmod -R g+w #{f}`
    else
      `chmod g+w #{f}`
    end
  end

  def make_directory(d, options = {})
    if File.directory?(d)
      puts "exist ".rjust(12).bright + d
    else
      FileUtils.mkdir d, options
      puts "create ".rjust(12).bright + d
    end
  end

  def install_file(source, dest, options = {})
    if File.exists?(dest)
      if FileUtils.identical?(source, dest)
        puts "identical ".rjust(12).bright + dest
      else
        puts "conflict ".rjust(12).color(:red) + dest
        overwrite = nil
        while overwrite.nil? do
          prompt = Readline.readline("Overwrite #{dest}? (enter \"h\" for help) [ynqdh] ")
          case prompt.downcase
          when "y"
            overwrite = true
          when "n"
            overwrite = false
          when "d"
            puts `diff -w #{source} #{dest}`
          when "h"
            puts %{Y - yes, overwrite
n - no, do not overwrite
q - quit, abort
d - diff, show the differences between the old and the new
h - help, show this help}
          when "q"
            raise "Abort new package"
          #else
            #overwrite = true
          end
        end

        if overwrite == true
          puts "force ".rjust(12).bright + dest
          FileUtils.install source, dest, options
        else
          puts "skip ".rjust(12).bright + dest
        end
      end
    else
      FileUtils.install source, dest, options
      puts "create ".rjust(12).bright + dest
    end
  end
end
