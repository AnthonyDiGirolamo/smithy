require 'spec_helper'

describe Package do
  describe '.search' do
    it "should return an array" do
      Package.search.class.should == Array
    end
    it "should find zlib" do
      Package.search("zlib").select{|s| s =~ /zlib/}.length.should >= 1
    end
  end
	describe '.search_by_name' do
    it "should find zlib" do
      Package.search_by_name("zlib").select{|s| s =~ /zlib/}.length.should >= 1
    end
	end
end

