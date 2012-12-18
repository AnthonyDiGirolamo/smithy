module Smithy

  class FormulaCommand
    class << self

      # helpers

      def formula_files
        @formula_files = Dir.glob(File.join(@@smithy_bin_root, "lib/formulas/*.rb")) if @formula_files.nil?
        @formula_files
      end

      def formula_names
        @formula_names = formula_files.collect{|f| File.basename(f,".rb")}.collect{|f| f.gsub("_formula","")} if @formula_names.nil?
        @formula_names
      end

      # construct a new fomula object given a package
      def build_formula(package, fname = nil)
        p = Package.new :path => package
        p.valid?

        fname = p.name if fname.blank?
        raise "unknown formula #{fname}" unless formula_names.include?(fname)

        required_formula = formula_files.select{|f| f =~ /#{fname}/}.first
        require required_formula
        f = "#{fname.camelize}_formula".constantize.new(:package => p)
        f.formula_file_path = required_formula
        return f
      end

      # formula subcommands

      def list
        puts formula_names
      end

      def install(options,args)
        packages = args.dup
        if args.empty?
          notice "Reading package names from STDIN..."
          packages = STDIN.readlines.map{|p| p.chomp}
        end
        raise "You must supply at least one package to install" if packages.empty?

        packages.each do |package|
          f = build_formula(package, options[:"formula-name"])
          f.package.create(:formula => true)
          d = DownloadCache.new(f).get
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
