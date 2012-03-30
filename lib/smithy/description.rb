module Smithy
  class Description
    attr_accessor :path, :package, :root, :arch, :www_root, :name

    def initialize(args = {})
      @package = args[:package]
      if @package.class == Package
        @path = args[:package].application_directory
        @root = @package.root
        @arch = @package.arch
        @name = @package.name
      else
        @root    = File.dirname args[:root]
        @arch    = File.basename args[:root]
        @name    = Package.normalize_name :name => args[:package], :root => @root, :arch => @arch
        @path    = File.join @root, @arch, @name
      end
      @www_root = args[:www_root]
    end

    def get_binding
      binding
    end

    def exceptions_file
      File.join(@path, Package::PackageFileNames[:exception])
    end

    def self.publishable?(path)
      exceptions_file = File.join(path, Package::PackageFileNames[:exception])
      publishable = true
      if File.exists? exceptions_file
        File.open(exceptions_file).readlines.each do |line|
          publishable = false if line =~ /^\s*noweb\s*$/
        end
      end
      return publishable
    end

    def publishable?
      Description.publishable?(path)
    end

    def deploy(args = {})
      options = {:verbose => false, :noop => false}
      options = {:verbose => true, :noop => true} if args[:dry_run]

      notice "Deploying #{path}"

      www_arch = File.join(www_root, "/#{arch.downcase}")

      FileUtils.mkdir_p www_root, options                  unless Dir.exists? www_root
      raise "Cannot access web-root directory #{www_root}" unless Dir.exists? www_root
      FileUtils.mkdir_p www_arch, options                  unless Dir.exists? www_arch
      raise "Cannot create web-root directory #{www_arch}" unless Dir.exists? www_arch

      description_file = File.join(path, "description.markdown")
      description_text = ""

      begin
        if File.exist? description_file
          f = File.open description_file
          d = Maruku.new(f.read)
          description_text = d.to_html
        else
          description_file = File.join(path, "description")
          f = File.open description_file
          description_text = f.read
        end
      rescue => exception
        raise "#{exception}\nCannot read #{description_file}"
      end

      alphabetical_output = File.join(www_arch, "/alphabetical.html")
      category_output     = File.join(www_arch, "/category.html")
      description_output  = File.join(www_arch, "/#{name.downcase}.html")

      unless args[:dry_run]
        d = File.open(description_output, "w+")
        d.write(description_text)
        d.close
      end
      puts "updated ".rjust(12).bright + description_output

      #TODO update alpha list
      #TODO update category list

      notice_success "SUCCESS #{path} published to web"
    end

  end
end
