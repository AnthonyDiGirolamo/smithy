class Cmake_formula < Formula
  homepage 'http://www.cmake.org/'
  url      'http://www.cmake.org/files/v2.8/cmake-2.8.10.2.tar.gz'
  md5      '097278785da7182ec0aea8769d06860c'

  def install
    module_list
    system "./bootstrap --prefix=#{prefix} --no-qt-gui"
    system "make all"
    system "make install"
  end
end
