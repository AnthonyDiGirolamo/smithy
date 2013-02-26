require 'smithy'
include Smithy
@@smithy_bin_root = File.expand_path(File.dirname(File.realpath(__FILE__))+ '/../')

describe FormulaCommand do
  it "stores formula directories" do
    FormulaCommand.formula_directories.should_not include("/tmp/smithy/formulas")
    FormulaCommand.prepend_formula_directory "/tmp/smithy/formulas"
    FormulaCommand.formula_directories.should include("/tmp/smithy/formulas")
    FormulaCommand.formula_directories.should include(File.join(ENV["HOME"], ".smithy/formulas"))
  end

  it "stores full formula paths" do
    FormulaCommand.formula_files.select{|f| f =~ /zlib/}.first.should include("/zlib_formula.rb")
  end

  it "stores known formulas names" do
    FormulaCommand.formula_names.should include("zlib")
  end

  describe "#formula_file_path" do
    it "returns the full file path of a formula" do
      FormulaCommand.formula_file_path("zlib").should include("/zlib_formula.rb")
    end
  end

  describe "#formula_contents" do
    it "returns the zlib formula file" do
      FormulaCommand.formula_contents("zlib").should include("ZlibFormula")
    end
  end
end
