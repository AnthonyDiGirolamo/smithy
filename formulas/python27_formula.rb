class Python27Formula < Formula
  homepage "www.python.org/"
  url "http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tar.bz2"

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
