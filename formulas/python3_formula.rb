class Python3Formula < Formula
  homepage "www.python.org/"
  url "http://www.python.org/ftp/python/3.3.0/Python-3.3.0.tar.bz2"

  def install
    module_list
    system "./configure --prefix=#{prefix} --enable-shared"
    system "make"
    system "make install"
  end
end
