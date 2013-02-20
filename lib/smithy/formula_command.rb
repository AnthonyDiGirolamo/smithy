module Smithy

  # This class acts as a controller for formula subcommands
  class FormulaCommand
    class << self
      attr_accessor :formula_directories

      # helpers
      # Collect known formula names in the following order
      # 1. formula directories specified on the command line
      # 2. smithy's built in formulas
      def formula_files
        if @formula_files.nil?
          @formula_directories = [] if @formula_directories.nil?
          @formula_directories << File.join(@@smithy_bin_root, "formulas")
          @formula_files = []
          @formula_directories.each {|dir| @formula_files += Dir.glob(File.join(File.expand_path(dir),"*.rb")).sort }
        end
        @formula_files
      end

      def formula_names
        @formula_names = formula_files.collect{|f| File.basename(f,".rb")}.collect{|f| f.gsub("_formula","")} if @formula_names.nil?
        @formula_names
      end

      def formula_file_path(formula_name)
        formula_files.select{|f| f =~ /#{formula_name}/}.first
      end

      # construct a new fomula object given a package
      def build_formula(package, fname = nil)

        fname, version, build = package.split("/") if fname.blank?

        raise "unknown formula #{fname}" unless formula_names.include?(fname)

        required_formula = formula_file_path(fname)
        require required_formula
        f = "#{fname.underscore.camelize}Formula".constantize.new(:path => required_formula)

        version = f.version if version.blank?
        build = operating_system if build.blank?

        package = [fname, version, build].join("/")

        p = Package.new :path => package
        p.valid?

        f.package = p

        return f
      end

      # formula subcommands

      def list(options,args)
        @formula_directories = options[:directories] || []

        puts formula_names
      end

      def display(options,args)
        @formula_directories = options[:directories] || []

        formula_name = args.first.split("/").first

        if File.exists? formula_file_path(formula_name)
          puts File.read(formula_file_path(formula_name))
        else
          raise "unkown formula '#{formula_name}'"
        end
      end

      def which(options,args)
        @formula_directories = options[:directories] || []

        formula_name = args.first.split("/").first

        if File.exists? formula_file_path(formula_name)
          puts formula_file_path(formula_name)
        else
          raise "unkown formula '#{formula_name}'"
        end
      end

      def install(options,args)
        @formula_directories = options[:directories] || []

        packages = args.dup
        if args.empty?
          notice "Reading package names from STDIN..."
          packages = STDIN.readlines.map{|p| p.chomp}
        end
        raise "You must supply at least one package to install" if packages.empty?

        packages.each do |package|
          f = build_formula(package, options[:"formula-name"])
          f.package.create(:formula => true)

          formula_prefix_contents = Dir["#{f.package.prefix}/*"]
          unless formula_prefix_contents.empty?
            overwrite = nil
            while overwrite.nil? do
              notice_conflict f.package.prefix
              prompt = Readline.readline(" "*FILE_NOTICE_COLUMNS+"Is not empty, delete contents? (enter \"h\" for help) [ynhq] ")
              case prompt.downcase
              when "y"
                overwrite = true
              when "n"
                overwrite = false
              when "h"
                indent = " "*FILE_NOTICE_COLUMNS
                puts indent+"y - yes, delete existing install"
                puts indent+"n - no, do not overwrite"
                puts indent+"h - help, show this help"
                puts indent+"q - exit now"
              when "q"
                raise "Abort new formula install"
              end
            end

            if overwrite
              formula_prefix_contents.each do |f|
                FileUtils.rm_rf(f)
              end
            end
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
        end
      end

    end #class << self
  end #FormulaCommand

end
