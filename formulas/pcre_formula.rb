class Pcre_formula < Formula
  homepage 'http://www.pcre.org/'
  url 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.32.tar.bz2'
  # mirror 'http://downloads.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.bz2'
  sha256 'a913fb9bd058ef380a2d91847c3c23fcf98e92dc3b47cd08a53c021c5cde0f55'

  def install
    system "./configure",
      "--disable-dependency-tracking",
      "--prefix=#{prefix}",
      "--enable-utf8",
      "--enable-unicode-properties",
      "--enable-pcregrep-libz"
      # "--enable-pcregrep-libbz2"
    system "make test"
    system "make install"
  end
end
