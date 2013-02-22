require 'active_support/core_ext/string'
require 'active_support/inflector'
require 'smithy'
include Smithy

describe Formula do
  it "knows it's name" do
    class TestFormula < Formula
    end
    TestFormula.formula_name.should == "test"
  end

  it "can run a defined install method" do
    class TestFormulaWithInstall < Formula
      def install
      end
    end
    TestFormulaWithInstall.new.should respond_to :install
  end

  it "raises an error if the install method is not implemented" do
    class EmptyTestFormula < Formula
    end

    expect { EmptyTestFormula.new.install }.to raise_error
  end

  it "has a homepage" do
    class HomepageTestFormula < Formula
      homepage "http://rspec.info/"
    end

    Formula.homepage.should be_nil
    HomepageTestFormula.homepage.should == "http://rspec.info/"
  end

  it "has a url" do
    class UrlTestFormula < Formula
      url "https://rubygems.org/downloads/rspec-2.12.0.gem"
    end

    Formula.url.should be_nil
    UrlTestFormula.url.should == "https://rubygems.org/downloads/rspec-2.12.0.gem"
  end

  it "can use homepage value" do
    class HomepageUrlTestFormula < Formula
      homepage "http://rspec.info/"
      url homepage
    end

    HomepageUrlTestFormula.inspect
    HomepageUrlTestFormula.url.should == "http://rspec.info/"
  end

  it "passes values to instances" do
    HomepageUrlTestFormula.url.should == "http://rspec.info/"
    HomepageUrlTestFormula.new.url.should == "http://rspec.info/"
  end
  it "has a hash"
  it "sets a version"
end

# require 'spec_helper'

# class Testzlib < Formula
# 	homepage 'http://zlib.net'
# 	url      'http://zlib.net/zlib-1.2.7.tar.gz'
# 	md5      '60df6a37c56e7c1366cca812414f7b85'

# 	def install
# 	end
# end

# class Testzlibempty < Formula
# end

# describe Formula do
# 	context 'with defined values' do
# 		subject { Testzlib.new }
# 		it { subject.url.should == 'http://zlib.net/zlib-1.2.7.tar.gz' }
# 		it { subject.homepage.should == 'http://zlib.net' }
# 		it { subject.md5.should == '60df6a37c56e7c1366cca812414f7b85' }
# 		it { subject.should respond_to(:install) }
# 	end

# 	context 'with excluded values' do
# 		subject { Testzlibempty.new }
# 		it { subject.url.should be_nil }
# 		it { subject.should_not respond_to(:install) }
# 	end
# end

# describe FormulaCommand do
#   describe '#list' do
#     it { FormulaCommand.formula_names.should include('zlib') }
#   end

#   describe '#build_formula' do
#     subject { FormulaCommand.build_formula('zlib/1.2.7/gnu4.2') }
#     it 'should detect name, version, and prefix' do
#       subject.name.should == 'zlib'
#       subject.version.should == '1.2.7'
#       subject.prefix.should include('zlib/1.2.7/gnu4.2')
#     end
#   end
# end
