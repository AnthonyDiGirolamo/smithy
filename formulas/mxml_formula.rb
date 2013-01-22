class Mxml_formula < Formula
  homepage 'http://www.minixml.org/'
  url 'http://ftp.easysw.com/pub/mxml/2.7/mxml-2.7.tar.gz'
  sha1 'a3bdcab48307794c297e790435bcce7becb9edae'

  modules do
    if build_name =~ /gnu/
      %w{gcc}
    elsif build_name =~ /intel/
      %w{intel}
    elsif build_name =~ /pgi/
      %w{pgi}
    end
  end

  def install
    if build_name =~ /gnu/
      ENV["CC"]  = "gcc"
      ENV["CXX"] = "g++"
      ENV["F77"] = "gfortran"
      ENV["FC"]  = "gfortran"
    elsif build_name =~ /intel/
      ENV["CC"]  = "icc"
      ENV["CXX"] = "icpc"
      ENV["F77"] = "ifort"
      ENV["FC"]  = "ifort"
    elsif build_name =~ /pgi/
      ENV["CC"]  = "pgcc"
      ENV["CXX"] = "pgCC"
      ENV["F77"] = "pgf77"
      ENV["FC"]  = "pgf90"
    end

    ENV["CFLAGS"]  = "-fPIC"

    module_list

    system "./configure --prefix=#{prefix} --disable-debug --disable-dependency-tracking --enable-shared"
    system "make"
    system "make install"
  end
end
