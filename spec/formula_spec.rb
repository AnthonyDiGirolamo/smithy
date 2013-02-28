require 'active_support/core_ext/string'
require 'active_support/inflector'
require 'smithy'
include Smithy

describe Formula do
  it "knows it's name" do
    module SmithyFormulaExamples
      class TestFormula < Formula
        homepage "homepage"
        url "url"
        def install
        end
      end
    end
    SmithyFormulaExamples::TestFormula.formula_name.should == "test"
    SmithyFormulaExamples::TestFormula.new.formula_name.should == "test"
  end

  it "can run a defined install method" do
    module SmithyFormulaExamples
      class TestFormulaWithInstall < Formula
        homepage "homepage"
        url "url"
        def install
        end
      end
    end
    SmithyFormulaExamples::TestFormulaWithInstall.new.should respond_to :install
  end

  it "has a homepage" do
    module SmithyFormulaExamples
      class HomepageTestFormula < Formula
        homepage "http://rspec.info/"
      end
    end
    Formula.homepage.should be_nil
    SmithyFormulaExamples::HomepageTestFormula.homepage.should == "http://rspec.info/"
  end

  it "has a url" do
    module SmithyFormulaExamples
      class UrlTestFormula < Formula
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
      end
    end
    Formula.url.should be_nil
    SmithyFormulaExamples::UrlTestFormula.url.should == "https://rubygems.org/downloads/rspec-2.12.0.gem"
  end

  it "can use homepage value" do
    module SmithyFormulaExamples
      class HomepageUrlTestFormula < Formula
        homepage "http://rspec.info/"
        url homepage
        def install
        end
      end
    end
    SmithyFormulaExamples::HomepageUrlTestFormula.inspect
    SmithyFormulaExamples::HomepageUrlTestFormula.url.should == "http://rspec.info/"
  end

  it "passes values to instances" do
    module SmithyFormulaExamples
      class HomepageUrlTestFormulaInstance < Formula
        homepage "http://rspec.info/"
        url homepage
        def install
        end
      end
    end
    SmithyFormulaExamples::HomepageUrlTestFormulaInstance.url.should == "http://rspec.info/"
    SmithyFormulaExamples::HomepageUrlTestFormulaInstance.new.url.should == "http://rspec.info/"
  end

  it "has a md5, sha1, sha2, or sha256 " do
    module SmithyFormulaExamples
      class HashTestFormula < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        md5 "1"
        sha1 "2"
        sha2 "3"
        sha256 "4"
      end
    end
    SmithyFormulaExamples::HashTestFormula.md5.should == "1"
    SmithyFormulaExamples::HashTestFormula.sha1.should == "2"
    SmithyFormulaExamples::HashTestFormula.sha2.should == "3"
    SmithyFormulaExamples::HashTestFormula.sha256.should == "4"
  end

  it "raises an error if the install method is not implemented" do
    module SmithyFormulaExamples
      class InvalidFormulaNoInstall < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
      end
    end
    expect { SmithyFormulaExamples::InvalidFormulaNoInstall.new }.to raise_error
  end

  it "raises an error if a homepage or url are unspecified" do
    module SmithyFormulaExamples
      class InvalidFormulaNoHomepageUrl < Formula
        def install
        end
      end
    end
    expect { SmithyFormulaExamples::InvalidFormulaNoHomepageUrl.new }.to raise_error
  end

  it "knows it's location on the filesystem" do
    module SmithyFormulaExamples
      class FormulaFilePath < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        def install
        end
      end
    end
    SmithyFormulaExamples::FormulaFilePath.new.formula_file.should =~ /formula.rb$/
  end

  it "sets a version explicitly" do
    module SmithyFormulaExamples
      class FormulaWithManualVersion < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        version "2.12.0"
        def install
        end
      end
    end
    SmithyFormulaExamples::FormulaWithManualVersion.new.version.should == "2.12.0"
  end

  it "guesses version number based on the url" do
    module SmithyFormulaExamples
      class FormulaWithUrlVersion < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        def install
        end
      end
    end
    SmithyFormulaExamples::FormulaWithUrlVersion.new.version.should == "2.12.0"
  end

  it "can specify modules to load" do
    module SmithyFormulaExamples
      class FormulaWithModules < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        modules ["ruby"]
        def install
        end
      end
    end
    SmithyFormulaExamples::FormulaWithModules.new.modules.should == ["ruby"]
  end

  it "can take a block for modules" do
    module SmithyFormulaExamples
      class FormulaWithModulesBlock < Formula
        homepage "http://rspec.info/"
        url "https://rubygems.org/downloads/rspec-2.12.0.gem"
        modules do
          ["ruby"] if version == "2.12.0"
        end
        def install
        end
      end
    end
    SmithyFormulaExamples::FormulaWithModulesBlock.new.modules.should == ["ruby"]
  end

  describe "#initialize" do
    before(:all) do
      class ZlibFormula < Formula
        homepage "http://zlib.net"
        url      "http://zlib.net/zlib-1.2.7.tar.gz"
        md5      "60df6a37c56e7c1366cca812414f7b85"
        modules do
          [name, version, build_name]
        end
        def install
          [build_name, prefix]
        end
      end
    end

    let(:p) { stub :name => "zlib",
                :version => "1.2",
             :build_name => "macos10.8_gnu4.2",
                 :prefix => "/tmp/smithy/zlib/1.2/macos10.8_gnu4.2" }

    it "takes a package" do
      z = ZlibFormula.new(p)
      z.name.should       == "zlib"
      z.version.should    == "1.2"
      z.build_name.should == "macos10.8_gnu4.2"
      z.prefix.should     == "/tmp/smithy/zlib/1.2/macos10.8_gnu4.2"
      z.install.should == ["macos10.8_gnu4.2","/tmp/smithy/zlib/1.2/macos10.8_gnu4.2"]
    end

    it "can set the package after initialization" do
      z = ZlibFormula.new
      z.set_package(p)
      z.name.should       == "zlib"
      z.version.should    == "1.2"
      z.build_name.should == "macos10.8_gnu4.2"
      z.prefix.should     == "/tmp/smithy/zlib/1.2/macos10.8_gnu4.2"
      z.install.should == ["macos10.8_gnu4.2","/tmp/smithy/zlib/1.2/macos10.8_gnu4.2"]
    end

    it "saves module purge commands", :if => ENV["MODULESHOME"] do
      z = ZlibFormula.new
      z.module_setup.should include("unset")
      z.module_setup.should include("export")
    end

    it "can take a block for modules and use name, version, build_name" do
      ZlibFormula.new.modules.should include "zlib"
      ZlibFormula.new.modules.should include "1.2.7"
      ZlibFormula.new(p).modules.should == ["zlib", "1.2", "macos10.8_gnu4.2"]
    end

  end
end

