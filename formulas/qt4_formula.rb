class Qt4Formula < Formula
  homepage "http://qt-project.org/"
  url "http://download.qt-project.org/official_releases/qt/4.8/4.8.5/qt-everywhere-opensource-src-4.8.5.tar.gz"
  sha256 "eb728f8268831dc4373be6403b7dd5d5dde03c169ad6882f9a8cb560df6aa138"

  module_commands do
    [ "purge" ]
  end

  def install
    module_list
    system "./configure --prefix=#{prefix}",
      "-system-libpng", "-system-zlib",
      "-confirm-license", "-opensource"
    system "make"
    system "make install"
  end
end
