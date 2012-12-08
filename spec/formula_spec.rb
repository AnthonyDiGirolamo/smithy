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
	context 'defines values' do
		subject { Testzlib.new }
		it { subject.url.should == 'http://zlib.net/zlib-1.2.7.tar.gz' }
		it { subject.homepage.should == 'http://zlib.net' }
		it { subject.md5.should == '60df6a37c56e7c1366cca812414f7b85' }
		it { subject.should respond_to(:install) }
	end

	context 'excludes values' do
		subject { Testzlibempty.new }
		it { subject.url.should be_nil }
		it { subject.should_not respond_to(:install) }
	end
end
