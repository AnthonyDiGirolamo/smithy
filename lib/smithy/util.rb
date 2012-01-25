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
		STDOUT.puts "==> "+message if STDOUT.tty?
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

  def load_system_config
    sysconfig_path = File.expand_path(File.join(@smithy_bin_root,@smithy_config_file))
    if File.exists? sysconfig_path
      @smithy_config_hash = YAML.load_file(sysconfig_path)
    else
      STDERR.puts "warning: Cannot read config file: #{sysconfig_path}"
    end
  end

  def get_arch(args = {})
    @hostname = `hostname`.chomp
    return args[:command_line_arch] unless args[:command_line_arch].nil?

    if @hostname =~ /(\D*)(\d*)/
      machine = $1
      arch = @smithy_config_hash.try(:[], :"hostname-architectures").try(:[], machine)
      return arch
    end
    return nil
  end

  def get_software_root(args = {})
    if args[:root].blank? || args[:arch].blank?
      raise """Cannot determine which architecture to build for.
       Please specify using --arch or add a '#{@hostname}' hostname entry to:
       #{@smithy_bin_root}/#{@smithy_config_file}"""
    end

    swroot = File.join(args[:root], args[:arch])
    raise "The software-root directory '#{swroot}' is not valid" unless Dir.exist?(swroot)
    return swroot
  end
end
