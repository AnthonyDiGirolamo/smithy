class SqliteFormula < Formula
  homepage "http://sqlite.org/"
  url      "http://sqlite.org/sqlite-autoconf-3071502.tar.gz"
  version  "3.7.15.2"
  sha1     "075732562183d560cd46a0d8d08b50bc44e34eac"

  def install
    module_list
    system "./configure --prefix=#{prefix}", "--disable-dependency-tracking", "--enable-dynamic-extensions"
    system "make"
    system "make install"
  end
end
