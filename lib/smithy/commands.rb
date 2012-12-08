module Smithy

  class FormulaCommand
    class << self
      def formula_files
        @formula_files = Dir.glob(File.join(@@smithy_bin_root, "lib/formulas/*.rb")) if @formula_files.nil?
        @formula_files
      end

      def formula_names
        @formula_names = formula_files.collect{|f| File.basename(f,".rb")}.collect{|f| f.gsub("_formula","")} if @formula_names.nil?
        @formula_names
      end

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
          p = Package.new :path => package
          p.valid?

          raise "unknown formula #{p.name}" unless formula_names.include?(p.name)
          required_formula = formula_files.select{|f| f =~ /#{p.name}/}.first
          require required_formula
          f = "#{p.name.camelize}_formula".constantize.new(:package => p)
          puts f.version
          f.install
        end
      end

    end
  end #FormulaCommand

end
