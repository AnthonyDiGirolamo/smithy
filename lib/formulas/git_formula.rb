class Git_formula < Formula
  homepage 'http://git-scm.com/'
  url      'http://git-core.googlecode.com/files/git-1.8.0.2.tar.gz'
  sha1     '1e1640794596da40f35194c29a8cc4e41c6b4f6d'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
