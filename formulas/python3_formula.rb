class Python3Formula < Formula
  homepage "www.python.org/"
  url "http://www.python.org/ftp/python/3.3.0/Python-3.3.0.tar.bz2"

  depends_on "sqlite"

  def install
    module_list

    ENV["CPPFLAGS"] = "-I#{sqlite.prefix}/include"
    ENV["LDFLAGS"]  = "-L#{sqlite.prefix}/lib"

    system "./configure --prefix=#{prefix} --enable-shared"
    system "make"
    system "make install"
  end
end
