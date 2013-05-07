class CurlFormula < Formula
  homepage "http://curl.haxx.se/"
  url      "http://curl.haxx.se/download/curl-7.30.0.tar.bz2"

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    <% if @builds.size > 1 %>
    <%= module_build_list @package, @builds %>

    set PREFIX <%= @package.version_directory %>/$BUILD
    <% else %>
    set PREFIX <%= @package.prefix %>
    <% end %>

    # Helpful ENV Vars
    setenv <%= @package.name.upcase %>_DIR $PREFIX
    setenv <%= @package.name.upcase %>_LIB "-L$PREFIX/lib"
    setenv <%= @package.name.upcase %>_INC "-I$PREFIX/include"

    # Common Paths
    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path MANPATH         $PREFIX/share/man
    prepend-path INFOPATH        $PREFIX/info
    prepend-path PKG_CONFIG_PATH $PREFIX/lib/pkgconfig
    prepend-path PYTHONPATH      $PREFIX/lib/python2.7/site-packages
    prepend-path PERL5PATH       $PREFIX/lib/perl5/site_perl
  MODULEFILE

  def install
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
