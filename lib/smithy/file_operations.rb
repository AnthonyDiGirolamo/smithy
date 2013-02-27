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
  FILE_NOTICE_COLUMNS = 12
  def notice_create(file)
    puts "create ".rjust(12).color(:green).bright + file
  end
  def notice_exist(file)
    puts "exists ".rjust(12).color(:blue).bright + file
  end
  def notice_link(file1, file2)
    puts "link ".rjust(12).bright + file1 + " -> " + file2
  end
  def notice_identical(file)
    puts "identical ".rjust(12).color(:blue).bright + file
  end
  def notice_conflict(file)
    puts "conflict ".rjust(12).color(:red).bright + file
  end
  def notice_force(file)
    puts "force ".rjust(12).color(:yellow).bright + file
  end
  def notice_skip(file)
    puts "skip ".rjust(12).bright + file
  end

  class FileOperations

    class << self

      def make_executable(f, options = {})
        unless options[:noop]
          p = File.stat(f).mode | 0111
          FileUtils.chmod p, f, options
        end
      end

      def set_group(f, new_group, options = {})
        method = :chown
        if options.has_key? :recursive
          options.reject!{|k,v| k.eql?(:recursive)}
          method = :chown_R
        end

        current_group = Etc.getgrgid(File.stat(f).gid).name rescue nil
        return if current_group.eql?(new_group) && method == :chown

        begin
          FileUtils.send method, nil, new_group, f, options
        rescue
          raise "Could not set group \"#{new_group}\" on \"#{f}\""
        end
      end

      def make_group_writable(f, options = {})
        f = f.path if f.class == File
        # FileUtils.chmod_R doesn't work well for combinations of files
        # with different bitmasks, it sets everything the same
        if options.has_key? :recursive
          command = "chmod -R g+w #{f}"
        else
          command = "chmod g+w #{f}"
          unless options[:noop]
            # Check to see if it's already group writeable
            # convert the integer to a string in base 8
            mode = File.stat(f).mode.to_s(8)
            # check the group bit, convert back to integer
            group_bit = mode[mode.size-2].to_i
            return if group_bit == 6 || group_bit == 7
          end
        end

        puts command if options[:verbose]
        `#{command}` unless options[:noop]
      end

      def make_directory(d, options = {})
        if File.directory?(d)
          notice_exist d
        else
          FileUtils.mkdir_p d, options
          notice_create d
        end
      end

      def make_symlink(old, new, options = {})
        if File.symlink?(new)
          notice_exist new
        else
          FileUtils.rm_f(new, options)
          FileUtils.ln_sf(old, new, options)
          notice_link old, new
        end
      end

      def install_file(source, dest, options = {})
        current_time = Time.now.to_i
        duplicate_dest = dest+"_copy_"+current_time.to_s
        installed = false

        force = options.try(:[],:force)
        force = Smithy::Config.global.try(:[], :"force") unless force
        options.reject!{|k,v| k==:force}

        if File.exists?(dest) && !force
          if FileUtils.identical?(source, dest)
            notice_identical dest
            installed = true
          else
            notice_conflict dest
            overwrite = nil
            while overwrite.nil? do
              prompt = Readline.readline(" "*FILE_NOTICE_COLUMNS+"Overwrite? (enter \"h\" for help) [ynsdh] ")
              case prompt.downcase
              when "y"
                overwrite = true
              when "n"
                overwrite = false
              when "s"
                overwrite = false
                duplicate = true
              when "d"
                puts `diff -uw #{dest} #{source}`
              when "h"
                indent = " "*FILE_NOTICE_COLUMNS
                puts indent+"y - yes, overwrite"
                puts indent+"n - no, do not overwrite"
                puts indent+"s - save to a separate file"
                puts indent+"d - diff, show the differences between the old and the new"
                puts indent+"h - help, show this help}"
              #when "q"
                #raise "Abort new package"
              #else
                #overwrite = true
              end
            end

            if overwrite
              notice_force dest
              FileUtils.install source, dest, options
              installed = true
            else
              if duplicate
                FileUtils.install source, duplicate_dest, options
                notice_create duplicate_dest
              else
                notice_skip dest
              end
            end
          end
        else
          FileUtils.install source, dest, options
          notice_create dest
          installed = true
        end

        return installed
      end

      def install_from_string(content, dest, options = {})
        if options[:noop]
          updated_file = File.join(ENV["HOME"]+"/.smithy_#{File.basename(dest)}_#{Time.now.to_i}")
        else
          updated_file = File.join(File.dirname(dest), ".#{File.basename(dest)}_#{Time.now.to_i}")
        end

        File.open(updated_file , "w+") do |f|
          f.write(content)
        end

        FileOperations.install_file updated_file, dest, options
        FileUtils.rm_f(updated_file) # Always remove
      end

      def render_erb(args = {})
        args[:options] = {} unless args[:options]
        options = {:noop => false, :verbose => false}
        options.merge!(args[:options])
        erb_filename  = args[:erb]
        dest          = args[:destination]

        if options[:noop]
          rendered_file = ENV["HOME"]+"/.#{File.basename(dest)}_#{Time.now.to_i}"
        else
          rendered_file = "#{File.dirname(dest)}/.#{File.basename(dest)}_#{Time.now.to_i}"
        end

        erb = ERB.new(File.read(erb_filename), nil, "<>")
        File.open(rendered_file, "w+") do |f|
          f.write erb.result(args[:binding])
        end

        FileOperations.install_file(rendered_file, dest, options)
        FileUtils.rm_f(rendered_file) # Always remove
      end

    end

  end
end
