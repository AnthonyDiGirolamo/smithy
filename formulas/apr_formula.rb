class AprFormula < Formula
  homepage "https://apr.apache.org/"
  url "http://apache.spinellicreations.com//apr/apr-1.4.6.tar.bz2"
  md5 "ffee70a111fd07372982b0550bbb14b7"

  version "1.4.6"

  def install
    module_list
    system "./configure --prefix=#{prefix} --enable-shared --disable-static --disable-debug"
    system "make install"
  end
end
