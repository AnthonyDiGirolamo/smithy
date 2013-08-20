class ZlibFormula < Formula
  homepage "http://zlib.net"
  url      "http://zlib.net/zlib-1.2.8.tar.gz"
  md5      "44d667c142d7cda120332623eab69f40"

  def install
    ENV["CC"] = "gcc"
    module_list
    system "which gcc"
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    set PREFIX <%= @package.prefix %>

    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path MANPATH         $PREFIX/share/man
  MODULEFILE
end
