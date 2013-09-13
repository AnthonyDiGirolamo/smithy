module Smithy
  # This class acts as a controller for formula subcommands
  class FormulaCommand
    # Return formula directories in order of precedence
    # 1. formula directories specified on the command line
    # 2. formulas located in ~/.smithy/formulas/
    # 3. smithy's built in formulas
    def self.formula_directories
      unless @formula_directories
        @formula_directories = [ File.join(Smithy::Config.homedir, ".smithy/formulas") ]
        if Smithy::Config.global[:"formula-directories"]
          Smithy::Config.global[:"formula-directories"].reverse.each do |dir|
            @formula_directories << dir
          end
        end
        @formula_directories << File.join(@@smithy_bin_root, "formulas")
      end
      @formula_directories
    end

    # Prepend a directory to the formula file paths
    def self.prepend_formula_directory(dir)
      @formula_directories.unshift(dir)
      @formula_directories
    end

    # Returns an array containing the full paths
    # to each file name in order of precedence
    def self.formula_files
      unless @formula_files
        @formula_files = []
        formula_directories.each do |dir|
          @formula_files += Dir.glob(File.join(File.expand_path(dir),"*.rb")).sort
        end
      end
      @formula_files
    end

    # Format the full file paths to display only the name
    def self.formula_names
      @formula_names = formula_files.collect{|f| File.basename(f,"_formula.rb")}.uniq unless @formula_names
      @formula_names
    end

    # Return the file path of a single formula file
    def self.formula_file_path(name)
      formula_files.select{|f| f =~ /\/#{name}_formula.rb/}.first
    end

    # Return the file contents of a formula
    def self.formula_contents(name)
      raise "unkown formula '#{name}'" unless formula_file_path(name).present? && File.exists?(formula_file_path(name))
      File.read(formula_file_path(name))
    end

    def self.initialize_directories(options = {})
      prepend_formula_directory(options[:d]) if options[:d]
    end

    def self.which_command(options,args)
      initialize_directories(options)
      formula_name = args.first.split("/").first
      puts formula_file_path(formula_name)
    end

    def self.display_command(options,args)
      initialize_directories(options)
      formula_name = args.first.split("/").first
      puts formula_contents(formula_name)
    end

    def self.list_command(options,args)
      initialize_directories(options)
      puts formula_names
    end

    # construct a new fomula object given a formula name or full name/version/build
    def self.build_formula(package, formula_name = nil)
      name, version, build = package.split("/")
      formula_name = name if formula_name.blank?
      raise "unknown formula #{formula_name}" unless formula_names.include?(formula_name)

      require formula_file_path(formula_name)

      formula_class = "#{formula_name.underscore.camelize}Formula".constantize
      version = formula_class.version if version.blank?
      build = operating_system        if build.blank?
      p = Package.new :path => [name, version, build].join("/"), :group_writable => !formula_class.disable_group_writable

      f = "#{formula_name.underscore.camelize}Formula".constantize.new(p)
      # Set the actual formula file path, otherwise it's just formula.rb
      f.formula_file = formula_file_path(formula_name)

      return f
    end

    def self.install_command(options,args)
      initialize_directories(options)

      packages = args.dup
      raise "You must supply at least one package to install" if packages.empty?

      packages.each do |package|
        f = build_formula(package, options[:"formula-name"])
        f.package.create(:formula => true)

        formula_prefix_contents = Dir["#{f.prefix}/*"]
        unless formula_prefix_contents.empty?
          # overwrite = "unknown"
          # while overwrite == "unknown" do
          #   notice_conflict f.package.prefix
          #   prompt = Readline.readline(" "*FILE_NOTICE_COLUMNS+"Is not empty, delete contents? (enter \"h\" for help) [ynhq] ")
          #   case prompt.downcase
          #   when "y"
          #     overwrite = true
          #   when "n"
          #     overwrite = false
          #   when "h"
          #     indent = " "*FILE_NOTICE_COLUMNS
          #     puts indent+"y - yes, delete existing install"
          #     puts indent+"n - no, do not overwrite"
          #     puts indent+"h - help, show this help"
          #     puts indent+"q - exit now"
          #   when "q"
          #     raise "Abort new formula install"
          #   end
          # end
          # if overwrite
          if options[:clean]
            notice "cleaning #{f.prefix}"
            formula_prefix_contents.each do |f|
              FileUtils.rm_rf(f)
            end
          end
          # end
        end

        if f.url.eql?("none")
          Dir.chdir File.join(f.package.prefix)
        else
          d = DownloadCache.new(f, options[:"formula-name"]).get
          raise "Download failure" unless d
          # f.package.extract(:archive => d, :overwrite => true)
          f.package.extract(:archive => d)
          Dir.chdir File.join(f.package.prefix, "source")
        end

        if f.run_install
          f.package.create_valid_build_file
          f.package.set_file_permissions_recursive

          if f.modulefile.present?
            f.create_modulefile
          elsif options[:"modulefile"]
            ModuleFile.new(:package => f.package).create
          end
        end
      end #packages.each
    end

    def self.new_command(options,args)
      @formula_name     = options[:name]
      @formula_name     = url_filename_basename(args.first) unless options[:name]
      @formula_name     = @formula_name.camelize
      @formula_url      = args.first
      @formula_homepage = options[:homepage]
      @formula_homepage = "#{URI(@formula_url).scheme}://#{URI(@formula_url).host}/" unless options[:homepage]

      destination = File.join(Smithy::Config.homedir, ".smithy/formulas")
      destination = Smithy::Config.global[:"formula-directories"].first if Smithy::Config.global[:"formula-directories"]
      FileUtils::mkdir_p(destination)

      destination = File.join(destination, "#{@formula_name.underscore}_formula.rb")
      FileOperations.render_erb :binding => binding,
        :erb         => File.join(@@smithy_bin_root, "etc/templates/formula.rb.erb"),
        :destination => destination
      if Smithy::Config.global[:"file-group-name"]
        FileOperations.set_group(destination, Smithy::Config.global[:"file-group-name"])
        FileOperations.make_group_writable(destination)
      end
    end

    def self.create_module_command(options,args)
      packages = args.dup
      raise "You must supply at least one package to install" if packages.empty?

      packages.each do |package|
        f = build_formula(package, options[:"formula-name"])
        if f.modulefile.present?
          f.create_modulefile
        else
          ModuleFile.new(:package => f.package).create
        end
      end
    end

  end #FormulaCommand

end
