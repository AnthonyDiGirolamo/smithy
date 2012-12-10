require 'spec_helper'

require 'smithy'
include Smithy

class Testzlib < Formula
	homepage 'http://zlib.net'
	url      'http://zlib.net/zlib-1.2.7.tar.gz'
	md5      '60df6a37c56e7c1366cca812414f7b85'

	def install
	end
end

class Testzlibempty < Formula
end

describe Formula do
	context 'with defined values' do
		subject { Testzlib.new }
		it { subject.url.should == 'http://zlib.net/zlib-1.2.7.tar.gz' }
		it { subject.homepage.should == 'http://zlib.net' }
		it { subject.md5.should == '60df6a37c56e7c1366cca812414f7b85' }
		it { subject.should respond_to(:install) }
	end

	context 'with excluded values' do
		subject { Testzlibempty.new }
		it { subject.url.should be_nil }
		it { subject.should_not respond_to(:install) }
	end
end

describe FormulaCommand do
  describe '#list' do
    it { FormulaCommand.formula_names.should include('zlib') }
  end

  describe '#build_formula' do
    subject { FormulaCommand.build_formula('zlib/1.2.7/gnu4.2') }
    it 'should detect name, version, and prefix' do
      subject.name.should == 'zlib'
      subject.version.should == '1.2.7'
      subject.prefix.should include('zlib/1.2.7/gnu4.2')
    end
  end
end
