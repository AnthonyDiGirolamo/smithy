class Zlib_formula < Formula
  homepage 'http://zlib.net'
  url      'http://zlib.net/zlib-1.2.7.tar.gz'
  md5      '60df6a37c56e7c1366cca812414f7b85'
  modules  %w{PrgEnv-gnu gcc}

  def install
    ENV['CC'] = 'gcc'
    module_list
    system "which gcc"
    system "./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
