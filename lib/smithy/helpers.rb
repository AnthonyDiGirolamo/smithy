# Smithy is freely available under the terms of the BSD license given below.
#
# Copyright (c) 2012. UT-BATTELLE, LLC. All rights reserved.
#
# Produced at the National Center for Computational Sciences in
# Oak Ridge National Laboratory.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# - Neither the name of the UT-BATTELLE nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
