class GitFormula < Formula
  homepage "https://git-core.googlecode.com/"
  url "https://git-core.googlecode.com/files/git-1.8.2.1.tar.gz"
  sha1 "ad9f833e509ba31c83efe336fd3599e89a39394b"
  depends_on "curl"

  def install
    module_list
    system "./configure --prefix=#{prefix} --with-curl=#{curl.prefix}"
    system "make"
    system "make install"
  end
end
