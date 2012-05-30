module Smithy
  class Description
    attr_accessor :path, :package, :root, :arch, :www_root, :name, :content, :categories, :versions, :builds

    def initialize(args = {})
      @www_root = args[:www_root]
      @package = args[:package]
      if @package.class == Package
        @path = args[:package].application_directory
        @root = @package.root
        @arch = @package.arch
        @name = @package.name
      else
        @root    = File.dirname args[:root]
        @arch    = File.basename args[:root]
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

    def sanitize_content!
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

      # Increment h tags by 2
      @content.gsub!(/<h(\d)>/)   {|m| "<h#{$1.to_i+1}>"}
      @content.gsub!(/<\/h(\d)>/) {|m| "</h#{$1.to_i+1}>"}

      # Don't use <code> inside a <pre>
      @content.gsub!(/<pre><code>/, "<pre>")
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
        else
          description_file = File.join(path, "description")
          f = File.open description_file
          @content = f.read

          #if !File.exists?(File.join(path, "description.markdown")) && name != "vasp" && name != "vasp5"
            #d = File.open(File.join(path, "description.markdown"), "w+")
            #k = Kramdown::Document.new(@content, :input => 'html')
            #d.write(k.to_kramdown)
            #d.close
          #end
        end
      rescue => exception
        raise "#{exception}\nCannot read #{description_file}"
      end

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
      root = args[:root]
      arch = args[:arch]
      www_arch = File.join(args[:www_root], arch)

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
