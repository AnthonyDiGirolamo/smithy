
                             T H E

                          S M I T H Y

                        S O F T W A R E

                    I N S T A L L A T I O N

                            T O O L


class ZlibFormula < Formula
  homepage "http://zlib.net"
  url      "http://zlib.net/zlib-1.2.8.tar.gz"
  md5      "44d667c142d7cda120332623eab69f40"

  def install
    module_list
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    module-whatis "<%= @package.name %> <%= @package.version %>"
    set PREFIX <%= @package.prefix %>
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path MANPATH         $PREFIX/share/man
  MODULEFILE
end

$ smithy formula install zlib

opt
├── smithyrc
├── formulas
|   └── zlib_formula.rb
└── mavericks
    └── zlib
        └── 1.2.8
            ├── modulefile
            |   └── zlib
            └── x86_64
                ├── include
                ├── lib
                ├── share
                └── source
