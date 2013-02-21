class VimFormula < Formula
  homepage "http://www.vim.org"
  url      "http://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2"

  version "7.3"

  def install
    module_list
    system "./configure --prefix=#{prefix} --with-features=huge"
    system "make"
    system "make install"
  end
end
