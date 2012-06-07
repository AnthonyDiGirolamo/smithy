module Smithy
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
          puts "exist ".rjust(12).bright + d
        else
          FileUtils.mkdir_p d, options
          puts "create ".rjust(12).bright + d
        end
      end

      def install_file(source, dest, options = {})
        current_time = Time.now.to_i
        duplicate_dest = dest+"_copy_"+current_time.to_s
        installed = false
        if File.exists?(dest)
          if FileUtils.identical?(source, dest)
            puts "identical ".rjust(12).bright + dest
            installed = true
          else
            puts "conflict ".rjust(12).color(:red) + dest
            overwrite = nil
            while overwrite.nil? do
              prompt = Readline.readline("Overwrite? (enter \"h\" for help) [ynsdh] ")
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
                puts %{y - yes, overwrite
n - no, do not overwrite
s - save to a separate file (#{duplicate_dest})
d - diff, show the differences between the old and the new
h - help, show this help}
              #when "q"
                #raise "Abort new package"
              #else
                #overwrite = true
              end
            end

            if overwrite
              puts "force ".rjust(12).bright + dest
              FileUtils.install source, dest, options
              installed = true
            else
              if duplicate
                FileUtils.install source, duplicate_dest, options
                puts "create ".rjust(12).bright + duplicate_dest
              else
                puts "skip ".rjust(12).bright + dest
              end
            end
          end
        else
          FileUtils.install source, dest, options
          puts "create ".rjust(12).bright + dest
          installed = true
        end

        return installed
      end

      def render_erb(args = {})
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
