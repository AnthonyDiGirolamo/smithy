class GitFormula < Formula
  homepage "http://git-scm.com/"
  version  "1.8.0.2"
  url      "http://git-core.googlecode.com/files/git-1.8.0.2.tar.gz"
  sha1     "1e1640794596da40f35194c29a8cc4e41c6b4f6d"

  depends_on "curl"

  def install
    system "./configure --prefix=#{prefix} --with-curl=#{curl.prefix}"
    system "make"
    system "make install"
  end
end
