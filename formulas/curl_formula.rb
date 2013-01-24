class CurlFormula < Formula
  homepage "http://curl.haxx.se/"
  url      "http://curl.haxx.se/download/curl-7.28.1.tar.bz2"
  md5      "26eb081c999b0e203770869427e9a93d"

  def install
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
