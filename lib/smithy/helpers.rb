# Smithy is freely available under the terms of the BSD license given below. {{{
#
# Copyright (c) 2012. UT-BATTELLE, LLC. All rights reserved.
#
# Produced by the National Center for Computational Sciences at Oak Ridge
# National Laboratory. Smithy is a based on SWTools, more information on SWTools
# can be found at: http://www.olcf.ornl.gov/center-projects/swtools/
#
# This product includes software produced by UT-Battelle, LLC under Contract No.
# DE-AC05-00OR22725 with the Department of Energy.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# }}}

module Smithy
  def notice(message)
    STDOUT.puts "==> ".color(:blue)+message #if STDOUT.tty?
  end

  def notice_warn(message)
    STDOUT.puts ("==> "+message).color(:yellow) #if STDOUT.tty?
  end

  def notice_info(message)
    STDOUT.puts (message).color(:blue) #if STDOUT.tty?
  end

  def notice_command(command, comment, width=40)
    STDOUT.puts command.ljust(width)+comment.color(:blue) #if STDOUT.tty?
  end

  def notice_params(params_hash)
    width = 0
    params_hash.keys.each do |key|
      width = key.to_s.size if key.to_s.size > width
    end
    params_hash.each do |key, value|
      STDOUT.puts "  " + key.to_s.ljust(width) + " " + value.to_s.color(:blue) #if STDOUT.tty?
    end
  end

  def notice_success(message)
    # if STDOUT.tty?
      STDOUT.puts "==> ".color(:green) + message.color(:green)
    # else
    #   STDOUT.puts message
    # end
  end

  def notice_fail(message)
    # if STDOUT.tty?
      STDOUT.puts ("==> "+message).color(:red)
    # else
    #   STDOUT.puts message
    # end
  end

  def notice_exception(message)
    STDERR.puts "==> ERROR: ".color(:red) + message
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

  concerning :OperatingSystemHelpers do
    included do
      def operating_system
        b = `uname -m`.chomp
        redhat = "/etc/redhat-release"
        suse = "/etc/SuSE-release"
        if File.exists? redhat
          # Red Hat Enterprise Linux Server release 6.3 (Santiago)
          # CentOS release 5.9 (Final)
          content = File.read(redhat)
          content =~ /([\d\.]+)/
          version = $1
          b = "rhel" if content =~ /Red Hat/
          b = "centos" if content =~ /CentOS/
          b += version
        elsif File.exists? suse
          # SUSE Linux Enterprise Server 11 (x86_64)
          # VERSION = 11
          # PATCHLEVEL = 1
          content = File.read(suse)
          content =~ /VERSION = (\d+)/
          version = $1
          content =~ /PATCHLEVEL = (\d+)/
          patch = $1
          b = "sles#{version}.#{patch}"
        end

        if `gcc --version 2>&1` =~ /gcc \((.*)\) ([\d\.]+)/
          b << "_gnu#{$2}"
        end
        return b
      end

      def cray_linux_version
        version = false
        version = ENV["XTOS_VERSION"]   if ENV["XTOS_VERSION"].present?
        version = ENV["CRAYOS_VERSION"] if ENV["CRAYOS_VERSION"].present?
        return version
      end

      def cray_system?
        cray_linux_version.present?
      end
    end
  end

  def url_filename(url)
    File.basename(URI(url).path)
  end

  def url_filename_version_number(url)
    version = url_filename(url)
    version = $1 if version =~ /([\d\.]+[\d])/
    version
  end

  def url_filename_basename(url)
    name = url_filename(url)
    name = $1 if name =~ /(.*?)-([\d\.]+[\d])/
    name
  end

  def get_python_version_from_build_name(build_name, separator: "/")
    if build_name =~ /python((\d+\.)?(\d+\.)?(\d+))/
      "python#{separator}#{$1}"
    else
      raise "cannot determine which python version based on the build_name: #{build_name}"
    end
  end

  def python_libdir(version)
    if version =~ /(\d+\.)?(\d+\.)?(\d+)/
      python_full_version = $&
      major_version = $1
      minor_version = $2 || $3
      minor_version.delete!(".")
      "python" + major_version + minor_version
    else
      ""
    end
  end

  def module_is_available?(mod)
    raise "$MODULESHOME is not set" unless ENV["MODULESHOME"].present?
    modulecmd = "modulecmd sh"
    modulecmd = "#{ENV["MODULESHOME"]}/bin/modulecmd sh" if File.exists?("#{ENV["MODULESHOME"]}/bin/modulecmd")
    module_avail = `#{modulecmd} avail -l #{mod} 2>&1`
    if module_avail =~ /^#{mod}/
      true
    else
      false
    end
  end

  def for_version(version)
    ("Version" + version.to_s.squish.gsub(/[\. ]/, "_")).to_sym
  end

  def config_value(value)
    result = Smithy::Config.config_file_hash.try(:[], value)
    raise "config_value #{value} does not exist in #{Smithy::Config.config_file_name}" if result.blank?
    result
  end

  def hostname(strip_trailing_numbers: false)
    h = Smithy::Config.hostname
    h.gsub!(/\d+$/, "") if strip_trailing_numbers
    h
  end

  def log_exception(e, argv, config)
    logfile = Smithy::Config.global[:"global-error-log"]
    if logfile.present?
      exception = {
       "time"        => DateTime.now,
       "user"        => `whoami`.chomp,
       "hostname"    => `hostname`.chomp,
       "working_dir" => Dir.getwd,
       "argv"        => argv,
       "config"      => config,
       "exception"   => e,
       "backtrace"   => e.backtrace
      }
      File.open(logfile, "a") do |f|
        f.write(exception.to_yaml)
      end
    end
  end

end
