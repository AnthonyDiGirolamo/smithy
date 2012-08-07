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

  def launch_editor(args = {})
    editor = args[:editor] || ENV['EDITOR']
    raise """Please specify which editor to launch using the
       $EDITOR environment variable or the --editor option.""" if editor.blank?

    arg_list = [ editor ]
    arg_list << "-O" if args[:split] && editor =~ /vim/

    if args[:split]
      args[:files].each{|f| arg_list << f}
    else
      arg_list << args[:files].first
    end

    status = Kernel::system(*arg_list)
  end

  def modulehelp(name)
    raise "$MODULEPATH is not set" unless ENV.has_key?('MODULEPATH')
    sout = ""
    #serr = ""
    status = Open4::popen4("script -q -c '#{ENV['MODULESHOME']}/bin/modulecmd sh help #{name}' /dev/null") do |pid, stdin, stdout, stderr|
      sout += stdout.read.strip
      #serr += stderr.read.strip
    end
    #if status.exitstatus.eql?(0)
    sout.gsub!(/\r/, '')
    #serr.gsub!(/\r/, '')
    return sout
    #list = ""
    # status = Open4::popen4(ENV['MODULESHOME']+"/bin/modulecmd ruby avail -t") do |pid, stdin, stdout, stderr|
    #   list = stderr.read.strip
    # end
    # if status.exitstatus.eql?(0)
    #   m = {}
    #   key = nil
    #   list.split(/^(.*:)$/).each do |line|
    #     next if line.empty?
    #     if key.nil?
    #       if line =~ /^(.*):$/
    #         key = $1
    #       end
    #     else
    #       m[key] = line.split("\n")
    #       m[key].reject!{|l| l.empty?}
    #       key = nil
    #     end
    #   end
    # end
  end

end
