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
          raise "The formula-directories option in $SMITHY_CONFIG should be an array" if Smithy::Config.global[:"formula-directories"].class != Array
          Smithy::Config.global[:"formula-directories"].reverse.each do |dir|
            @formula_directories << dir
          end
        end
        @formula_directories << File.join(Smithy::Config.bin_root, "formulas")
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

    def self.formula_basename(f)
      File.basename(f, "_formula.rb")
    end

    # Format the full file paths to display only the name
    def self.formula_names
      @formula_names = formula_files.collect{|f| formula_basename(f)}.uniq unless @formula_names
      @formula_names
    end

    def self.formula_versions
      formula_versions = []
      formula_files.each do |f|
        formula_contents = File.open(f).read rescue ""
        unless formula_contents.blank?
          version_number     = $1                              if formula_contents =~ /^\s+version\s+['"](.*?)['"]$/
          url_version_number = url_filename_version_number($1) if formula_contents =~ /^\s+url\s+['"](.*?)['"]$/

          if version_number.present? || url_version_number != "none"
            formula_versions << formula_basename(f) + "/" + (version_number || url_version_number)
          end

          formula_contents.scan(/^\s+concern\s+:Version(.*?)\s+do$/).each do |m|
            formula_versions << formula_basename(f) + "/" + m.first.gsub(/\_/, ".")
          end

          formula_contents.scan(/^\s+concern\s+for_version\(['"](.*?)['"]\)\s+do$/).each do |m|
            formula_versions << formula_basename(f) + "/" + m.first
          end
        end
      end
      formula_versions.uniq
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
      formula_constant_name = "#{formula_name.underscore.camelize}Formula"

      if version.present?
        version_concern = "Version" + version.gsub(/\./, "_")
        if formula_constant_name.constantize.const_defined?(version_concern)
          formula_constant_name.constantize.class_eval "include #{version_concern}"
        end
      end

      f = formula_constant_name.constantize.new

      # Set the actual formula file path, otherwise it's just formula.rb
      f.formula_file = formula_file_path(formula_name)

      guessing_new_name = true if version.blank? || build.blank?
      version = f.version      if version.blank?
      build = operating_system if build.blank?

      if guessing_new_name
        guessed_install_path = File.join(
          # Smithy::Config.global[:full_software_root_path],
          [name, version, build].join("/") )

        use_guessed_name = false
        while use_guessed_name == false do
          prompt = Readline.readline("Did you mean #{guessed_install_path} ? (enter \"h\" for help) [ynh] ")
          case prompt.downcase
          when "y"
            use_guessed_name = true
          when "n"
            notice_warn "Please re-run with a full target name including version and build name."
            raise "Aborting install"
          when "h"
            puts "    y - yes, continue"
            puts "    n - no, abort"
            puts "    h - help, show this help"
          end
        end
      end

      p = Package.new :path => [name, version, build].join("/"), :group_writable => f.group_writable?
      f.set_package(p) if p.valid?

      return f
    end

    def self.install_command(options,args)
      initialize_directories(options)

      packages = args.dup
      if args.empty?
        notice "Reading package names from STDIN..."
        packages = STDIN.readlines.map{|p| p.strip}
      end

      raise "You must supply at least one package to install" if packages.empty?

      packages.each do |package|
        f = build_formula(package, options[:"formula-name"])

        if options["skip-installed"] && File.exists?(f.package.valid_build_file)
          notice_success "Already Installed #{f.prefix}"
          next
        end

        f.check_supported_build_names
        f.check_dependencies
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


        software_roots_from_command_line = options[:"additional-roots"].try(:split,",") || []
        unless software_roots_from_command_line.empty?
          f.additional_software_roots = software_roots_from_command_line
        end

        if f.run_install && f.run_test
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
      @formula_name     = @formula_name.underscore.camelize
      @formula_url      = args.first
      @formula_homepage = options[:homepage]
      @formula_homepage = "#{URI(@formula_url).scheme}://#{URI(@formula_url).host}/" unless options[:homepage]

      destination = File.join(Smithy::Config.homedir, ".smithy/formulas")
      destination = Smithy::Config.global[:"formula-directories"].first if Smithy::Config.global[:"formula-directories"]
      FileUtils::mkdir_p(destination)

      destination = File.join(destination, "#{@formula_name.underscore}_formula.rb")
      FileOperations.render_erb :binding => binding,
        :erb         => File.join(Smithy::Config.bin_root, "etc/templates/formula.rb.erb"),
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
