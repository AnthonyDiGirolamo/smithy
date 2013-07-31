class GitFormula < Formula
  homepage "https://git-core.googlecode.com/"
  url "https://git-core.googlecode.com/files/git-1.8.3.4.tar.gz"
  sha1 "fe633d02f7d964842d7ea804278b75120fc60c11"
  depends_on "curl"

  module_commands [ "purge" ]

  def install
    module_list
    system "./configure --prefix=#{prefix} --with-curl=#{curl.prefix}"
    system "make"
    system "make install"

    system "mkdir -p #{prefix}/share/man"
    system "curl -O https://git-core.googlecode.com/files/git-manpages-1.8.3.4.tar.gz"
    system "cd #{prefix}/share/man && tar xf #{prefix}/source/git-manpages-1.8.3.4.tar.gz"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    set PREFIX <%= @package.prefix %>

    prepend-path PATH      $PREFIX/bin
    prepend-path PERL5PATH $PREFIX/lib64/perl5/site_perl
    prepend-path MANPATH   $PREFIX/share/man
    setenv       GITDIR    $PREFIX
  MODULEFILE
end
