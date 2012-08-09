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

module Smithy
  module Format
    def self.print_column_list(items)
      max_size = 0
      items.each { |m| max_size = m.size if m.size > max_size }
      width = `tput cols`.to_i
      columns = (width/(max_size+3.0)).ceil
      items_per_column = (items.size/columns.to_f).ceil

      items_copy = items.dup
      s = []
      columns.times do
        s << items_copy.slice!(0, items_per_column)
      end
      while s.last.size < items_per_column do
        s.last << ""
      end
      table = Terminal::Table.new :rows => s.transpose
      puts table.to_s
    end

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
