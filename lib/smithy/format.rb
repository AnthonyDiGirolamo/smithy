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
          source = s+'/rebuild'
          if File.exist?(source)
            f = File.stat(source)
          else
            f = File.stat(s)
          end
          row << f.mtime.strftime("%Y-%m-%d %H:%M:%S")
          begin
            user = Etc.getpwuid(f.uid)
            row << user.try(:name)
            row << user.try(:gecos)
          rescue
            row << 'unknown'
            row << 'unknown'
          end
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
          row = []
          row << s
          source = s+'/rebuild'
          if File.exist?(source)
            f = File.stat(source)
          else
            f = File.stat(s)
          end
          row << f.mtime.strftime("%Y-%m-%d %H:%M:%S")
          begin
            user = Etc.getpwuid(f.uid)
            row << user.try(:name)
            row << user.try(:gecos)
          rescue
            row << 'unknown'
            row << 'unknown'
          end
          unless user.blank?
            row << user.try(:name)
            row << user.try(:gecos)
          end
          puts row.join(',')
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
