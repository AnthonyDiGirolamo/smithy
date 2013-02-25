require 'smithy'
include Smithy
@@smithy_bin_root = File.expand_path(File.dirname(File.realpath(__FILE__))+ '/../')

describe FormulaCommand do
  it "stores formula directories" do
    FormulaCommand.formula_directories.should_not include("/tmp/smithy/formulas")
    FormulaCommand.formula_directories << "/tmp/smithy/formulas"
    FormulaCommand.formula_directories.should include("/tmp/smithy/formulas")
    FormulaCommand.formula_directories.should include(File.join(ENV["HOME"], ".smithy/formulas"))
  end
  it "lists known formulas"
end
