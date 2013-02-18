class OpenmpiFormula < Formula
  homepage "http://www.open-mpi.org"
  url      "http://www.open-mpi.org/software/ompi/v1.6/downloads/openmpi-1.6.3.tar.bz2"
  md5      "eedb73155a7a40b0b07718494298fb25"
  sha1     "a61aa2dee4c47d93d88e49ebed36de25df4f6492"

  modules do
    if build_name =~ /gnu/
      if build_name =~ /gnu4.6.2/
        ["gcc/4.6.2"]
      else
        ["gcc"]
      end
    elsif build_name =~ /intel/
      ["intel"]
    elsif build_name =~ /pgi/
      ["pgi"]
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
    module_list
    system "./configure --prefix=#{prefix} --with-platform=optimized --enable-static --enable-contrib-no-build=vt"
    system "make"
    system "make install"
  end
end
