module Smithy
  # This class acts as a controller for formula subcommands
  class FormulaCommand
    class << self
      # Return formula directores in order of precedence
      # 1. formula directories specified on the command line
      # 2. formulas located in ~/.smithy/formulas/
      # 3. smithy's built in formulas
      def formula_directories
        unless @formula_directories
          @formula_directories = [
            File.join(ENV["HOME"], ".smithy/formulas"),
            File.join(@@smithy_bin_root, "formulas")
          ]
        end
        @formula_directories
      end

      # Prepend a directory to the formula file paths
      def prepend_formula_directory(dir)
        @formula_directories.unshift(dir)
        @formula_directories
      end

      # Returns an array containing the full paths
      # to each file name in order of precedence
      def formula_files
        unless @formula_files
          @formula_files = []
          formula_directories.each do |dir|
            @formula_files += Dir.glob(File.join(File.expand_path(dir),"*.rb")).sort
          end
        end
        @formula_files
      end

      # Format the full file paths to display only the name
      def formula_names
        @formula_names = formula_files.collect{|f| File.basename(f,"_formula.rb")}.uniq unless @formula_names
        @formula_names
      end

      # Return the file path of a single formula file
      def formula_file_path(name)
        formula_files.select{|f| f =~ /#{name}_formula.rb/}.first
      end

      # Return the file contents of a formula
      def formula_contents(name)
        raise "unkown formula '#{formula_name}'" unless File.exists? formula_file_path(name)
        File.read(formula_file_path(name))
      end

      def initialize_directories(options)
        prepend_formula_directory(options[:d]) if options[:d]
      end

      def which_command(options,args)
        initialize_directories(options)
        formula_name = args.first.split("/").first
        puts formula_file_path(formula_name)
      end

      def display_command(options,args)
        initialize_directories(options)
        formula_name = args.first.split("/").first
        puts formula_contents(formula_name)
      end

      def list_command(options,args)
        initialize_directories(options)
        puts formula_names
      end

      # construct a new fomula object given a formula name or full name/version/build
      def build_formula(package, formula_name = nil)
        name, version, build = package.split("/")
        formula_name = name if formula_name.blank?
        raise "unknown formula #{formula_name}" unless formula_names.include?(formula_name)

        require formula_file_path(formula_name)
        f = "#{formula_name.underscore.camelize}Formula".constantize.new

        version = f.version      if version.blank?
        build = operating_system if build.blank?
        p = Package.new :path => [name, version, build].join("/")
        f.set_package(p) if p.valid?

        return f
      end

      def install_command(options,args)
        initialize_directories(options)

        packages = args.dup
        raise "You must supply at least one package to install" if packages.empty?

        packages.each do |package|
          f = build_formula(package, options[:"formula-name"])
          f.package.create(:formula => true)

          formula_prefix_contents = Dir["#{f.prefix}/*"]
          unless formula_prefix_contents.empty?
            # overwrite = nil
            # while overwrite.nil? do
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
            notice "cleaning #{f.prefix}"
              formula_prefix_contents.each do |f|
                FileUtils.rm_rf(f)
              end
            # end
          end

          d = DownloadCache.new(f, options[:"formula-name"]).get
          raise "Download failure" unless d
          # f.package.extract(:archive => d, :overwrite => true)
          f.package.extract(:archive => d)

          ModuleFile.new(:package => f.package).create if options[:"modulefile"]

          Dir.chdir File.join(f.package.prefix, "source")
          if f.run_install
            f.package.create_valid_build_file
            f.package.set_file_permissions_recursive
          end
        end #packages.each
      end

    end #class << self
  end #FormulaCommand

end
