require 'terminal-table'

module Smithy
  module Format
    class Table
      def before
        @@table = Terminal::Table.new :headings => %w(Software Last_Modified User_ID User_Name)
      end

      def format(software, root)
        software.each do |s|
          row = []
          row << s
          f = File.stat(s+'/rebuild')
          row << f.mtime.strftime("%Y-%m-%d %H:%M:%S")
          user = Etc.getpwuid(f.uid)
          row << user.try(:name)
          row << user.try(:gecos)
          @@table << row
        end
      end

      def after
        puts @@table.to_s
      end
    end

    class CSV
      def before
      end

      def format(software, root)
        software.each do |s|
          output = []
          output << s
          f = File.stat(s+'/rebuild')
          output << f.mtime.strftime("%Y-%m-%d %H:%M:%S")
          user = Etc.getpwuid(f.uid)
          unless user.blank?
            output << user.try(:name)
            output << user.try(:gecos)
          end
          puts output.join(',')
        end
      end

      def after
      end
    end

    class Path
      def before ; end

      def format(software, root)
        puts software
      end

      def after ; end
    end

    class Name
      def before ; end

      def format(software, root)
        puts software.collect{|s| s.gsub(/#{root}\//, '')}
      end

      def after ; end
    end
  end
end
