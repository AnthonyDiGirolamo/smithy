class SzipFormula < Formula
  homepage "http://www.hdfgroup.org/doc_resource/SZIP/"
  url      "http://www.hdfgroup.org/ftp/lib-external/szip/2.1/src/szip-2.1.tar.gz"
  md5      "9229ef21fe4471281f0b632eb70376b1"

  modules do
    if build_name =~ /gnu/
      [ "gcc" ]
    elsif build_name =~ /intel/
      [ "intel" ]
    elsif build_name =~ /pgi/
      [ "pgi" ]
    end
  end

  def install
    if build_name =~ /gnu/
      ENV["CC"]  = "gcc"
      ENV["CXX"] = "g++"
      ENV["F77"] = "gfortran"
      ENV["FC"]  = "gfortran"
      ENV["LDFLAGS"] = "-lm"
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
    module_list
    system "./configure --prefix=#{prefix} --disable-shared"
    system "make"
    system "make install"
  end
end
