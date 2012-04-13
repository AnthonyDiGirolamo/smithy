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
      STDERR.puts "warning: Cannot read config file: #{sysconfig_path}"
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

  def module_build_list(package, builds, args = {})
    output = ""
    environments = [
      {:prg_env => "PrgEnv-gnu",       :compiler_name => "gcc",       :human_name => "gnu",       :regex => /(gnu|gcc)(.*)/},
      {:prg_env => "PrgEnv-pgi",       :compiler_name => "pgi",       :human_name => "pgi",       :regex => /(pgi)(.*)/},
      {:prg_env => "PrgEnv-intel",     :compiler_name => "intel",     :human_name => "intel",     :regex => /(intel)(.*)/},
      {:prg_env => "PrgEnv-cray",      :compiler_name => "cce",       :human_name => "cray",      :regex => /(cce|cray)(.*)/},
      {:prg_env => "PrgEnv-pathscale", :compiler_name => "pathscale", :human_name => "pathscale", :regex => /(pathscale)(.*)/}
    ]

    environments.each_with_index do |e,i|
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
          end
          output << "  } else {\n"
          output << "    set BUILD #{sub_builds.last}\n"
          output << "  }\n"
        else
          output << "  set BUILD #{builds[j]}\n"
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
