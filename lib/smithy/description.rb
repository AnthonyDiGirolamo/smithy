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
  class Description
    attr_accessor :path, :package, :root, :arch, :www_root, :name, :content, :categories, :versions, :builds

    def initialize(args = {})
      @www_root = Smithy::Config.web_root
      @package = args[:package]
      if @package.class == Package
        @path = args[:package].application_directory
        @root = @package.root
        @arch = @package.arch
        @name = @package.name
      else
        @root = Smithy::Config.root
        @arch = Smithy::Config.arch
        if @package == 'last'
          @name = last_prefix.split('/').try(:first)
        else
          @name = Package.normalize_name :name => args[:package], :root => @root, :arch => @arch
        end
        @path    = File.join @root, @arch, @name
      end
      @categories = []
    end

    def valid?
      raise "Cannot find the package #{@path}" unless Dir.exists? @path
      return true
    end

    def exceptions_file
      File.join(@path, Package::PackageFileNames[:exception])
    end

    def self.publishable?(path)
      exceptions_file = File.join(path, Package::PackageFileNames[:exception])
      description_file = File.join(path, "description")
      publishable = true
      if File.exists?(exceptions_file) && ( File.exists?(description_file) || File.exists?(description_file+".markdown") )
        File.open(exceptions_file).readlines.each do |line|
          publishable = false if line =~ /^\s*noweb\s*$/
        end
      end
      return publishable
    end

    def publishable?
      Description.publishable?(path)
    end

    def remove_ptag_linebreaks!
      # Find paragraph tag contents
      results = []
      @content.scan(/<p>(.*?)<\/p>/m) {|m| results << [m.first, Regexp.last_match.offset(0)[0]] }
      newlines = []
      # For each paragraph
      results.each do |string, index|
        # Find newlines and save their index
        # index + 3 to accomodate '<p>'
        string.scan(/\n/) {|m| newlines << index+3+Regexp.last_match.offset(0)[0] }
      end
      # Replace the newlines with spaces
      newlines.each {|i| @content[i] = ' '}
    end

    def sanitize_content!
      # Increment h tags by 2
      @content.gsub!(/<h(\d)>/)   {|m| "<h#{$1.to_i+1}>"}
      @content.gsub!(/<\/h(\d)>/) {|m| "</h#{$1.to_i+1}>"}

      # Don't use <code> inside a <pre>
      @content.gsub!(/<pre(.*?)><code>/) {|m| "<pre#{$1}>"}
      @content.gsub!(/<\/code><\/pre>/, "</pre>")
    end

    def parse_categories
      if @content =~ /Categor(y|ies):\s+(.*?)(<\/p>)$/i
        @categories = $2.split(',')
        @categories.map do |t|
          t.downcase!
          t.strip!
        end
      end
    end

    def render_version_table
      universal = false
      @version_table = {}
      Package.alternate_versions(@path).each do |v|
        @version_table[v] = Package.alternate_builds(File.join(@path, v))
        universal = true if @version_table[v].include?("universal") || @version_table[v].include?("binary")
      end

      if universal
        erb_file = File.join(@@smithy_bin_root, "/etc/templates/web/version_list.html.erb")
      else
        erb_file = File.join(@@smithy_bin_root, "/etc/templates/web/version_table.html.erb")
      end
      erb = ERB.new(File.read(erb_file), nil, "<>")
      return erb.result(binding)
    end

    def deploy(args = {})
      options = {:verbose => false, :noop => false}
      options = {:verbose => true, :noop => true} if args[:dry_run]

      www_arch = File.join(www_root, "/#{arch.downcase}")

      FileUtils.mkdir_p www_root, options                  unless Dir.exists? www_root
      raise "Cannot access web-root directory #{www_root}" unless Dir.exists? www_root
      FileUtils.mkdir_p www_arch, options                  unless Dir.exists? www_arch
      raise "Cannot create web-root directory #{www_arch}" unless Dir.exists? www_arch

      description_file = File.join(path, "description.markdown")

      begin
        if File.exist? description_file
          f = File.open description_file
          d = Kramdown::Document.new(f.read, :auto_ids => false)
          @content = d.to_html
          remove_ptag_linebreaks!
        else
          description_file = File.join(path, "description")
          f = File.open description_file
          @content = f.read
        end
      rescue => exception
        raise "#{exception}\nCannot read #{description_file}"
      end

      @content += render_version_table
      sanitize_content!
      parse_categories

      description_output  = File.join(www_arch, "/#{name.downcase}.html")
      unless args[:dry_run]
        d = File.open(description_output, "w+")
        d.write(@content)
        d.close
      end
      puts "updated ".rjust(12).bright + description_output

      #TODO update category list

      #notice_success "SUCCESS #{path} published to web"
    end

    def self.update_page(file = 'alphabetical', args = {})
      root = Smithy::Config.root
      arch = Smithy::Config.arch
      www_arch = File.join(Smithy::Config.web_root, arch)

      unless args[:descriptions].nil?
        @descriptions = args[:descriptions]
        @descriptions.sort! {|x,y| x.name <=> y.name}

        #tags.each do |tag|
          #t = tag.gsub(/^ *| *$|"/, '').downcase
          #@packages[@last_package][:tags] << t
          #@tags[t] = [] unless @tags.has_key?(t)
          #@tags[t] << name
        #end
        #@max_tag_count = 0
        #@min_tag_count = 1000000
        #@tags.each do |tag|
          #@max_tag_count = tag[1].size if tag[1].size > @max_tag_count
          #@min_tag_count = tag[1].size if tag[1].size < @min_tag_count
        #end
      end

      @packages = Package.all_web :root => File.join(root,arch)
      @packages.collect!{|p| Package.normalize_name(:name => p, :root => root, :arch => arch)}
      @packages.sort!

      erb_file = File.join(@@smithy_bin_root, "/etc/templates/web/#{file}.html.erb")
      output = File.join(www_arch, "/#{file}.html")

      erb = ERB.new(File.read(erb_file), nil, "<>")
      unless args[:dry_run]
        File.open(output, "w+") do |f|
          f.write erb.result(binding)
        end
      end
      #puts erb.result(binding)

      puts "updated ".rjust(12).bright + output
    end

  end
end
