class Python27Formula < Formula
  homepage "www.python.org/"
  url "http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tar.bz2"

  def install
    module_list
    system "./configure --prefix=#{prefix} --enable-shared"
    system "make"
    system "make install"
  end
end
