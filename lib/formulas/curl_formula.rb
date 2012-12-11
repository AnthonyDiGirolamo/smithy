class Curl_formula < Formula
  homepage 'http://curl.haxx.se/'
  url      'http://curl.haxx.se/download/curl-7.28.1.tar.bz2'

  def install
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
