class OpensslFormula < Formula
  homepage 'http://openssl.org'
  url 'http://openssl.org/source/openssl-1.0.1e.tar.gz'
  sha256 'f74f15e8c8ff11aa3d5bb5f276d202ec18d7246e95f961db76054199c69c1ae3'

  module_commands [ "purge" ]

  def install
    module_list

    system "./config",
      "--prefix=#{prefix}",
      "zlib-dynamic",
      "shared"

    system "make"
    system "make test"
    system "make install"
  end

end
