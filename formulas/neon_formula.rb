class NeonFormula < Formula
  homepage 'http://www.webdav.org/neon/'
  url 'http://www.webdav.org/neon/neon-0.29.6.tar.gz'
  sha1 'ae1109923303f67ed3421157927bc4bc29c58961'

  version "0.29.6"

  def install
    module_list
    system "./configure --prefix=#{prefix} --enable-shared --disable-static --with-ssl --disable-debug"
    system "make install"
  end
end
