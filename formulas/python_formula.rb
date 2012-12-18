class Python_formula < Formula
  homepage 'www.python.org/'
  url do
    if version == '3.3.0'
      'http://www.python.org/ftp/python/3.3.0/Python-3.3.0.tar.bz2'
    elsif version == '2.7.3'
      'http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tar.bz2'
    end
  end

  def install
    module_list
    system "./configure --prefix=#{prefix} --enable-shared"
    system "make"
    system "make install"
  end
end
