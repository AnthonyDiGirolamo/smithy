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

      def build_formula(package)
        p = Package.new :path => package

        p.valid?
        raise "unknown formula #{p.name}" unless formula_names.include?(p.name)

        required_formula = formula_files.select{|f| f =~ /#{p.name}/}.first
        require required_formula
        return "#{p.name.camelize}_formula".constantize.new(:package => p)
      end

      def checksum_download(file, checksum)
        # md5sum = `md5sum #{file}`.split[0].strip.chomp
        require 'digest/md5'
        digest = Digest::MD5.hexdigest(File.read(file))
        if checksum != digest
          raise <<-EOF.strip_heredoc
            file does not match expected MD5 checksum
                   expected: #{checksum}
                   got:      #{md5sum}
          EOF
        end
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
          f = build_formula(package)
          f.package.create(:formula => true)
          downloaded_file = f.package.download(f.url)
          checksum_download(downloaded_file, f.md5) if f.md5
          # f.package.extract(:archive => downloaded_file, :overwrite => true)
          f.package.extract(:archive => downloaded_file)

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
