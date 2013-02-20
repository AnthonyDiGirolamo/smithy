class SubversionFormula < Formula
  homepage "http://subversion.apache.org/"
  url "http://mirror.cogentco.com/pub/apache/subversion/subversion-1.7.8.tar.bz2"
  sha1 "12c7d8d5414bba74c9777c4d1dae74f152df63c2"

  version "1.7.8"

  depends_on ["neon", "apr", "apr-util", "sqlite"]

  def install
    module_list

    system "./configure",
      "--prefix=#{prefix}",
      "--with-ssl",
      "--with-zlib=/usr",
      "--with-sqlite",
      "--with-neon=#{neon.prefix}",
      "--with-apr=#{apr.prefix}",
      "--with-apr-util=#{apr_util.prefix}",
      "--with-sqlite=#{sqlite.prefix}"

    system "make install"
  end
end
