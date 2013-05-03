class NcoFormula < Formula
  homepage "http://nco.sourceforge.net/"
  url "http://nco.sourceforge.net/src/nco-4.3.0.tar.gz"
  md5 "7dc000805441cc30ff9de837e088df34"

  modules ["PrgEnv-gnu", "netcdf", "hdf5", "gsl", "java"]

  depends_on ["udunits", "gsl", "expat", "antlr2"]

  def install
    module_list
    ENV["CC"]      = "gcc"
    ENV["CXX"]     = "g++"

    ENV["CPPFLAGS"] = "-I#{expat.prefix}/include"
    ENV["LDFLAGS"] = [
      "-L#{expat.prefix}/lib",
      "-Wl,-rpath,#{expat.prefix}/lib",
      "-Wl,-rpath,/opt/gcc/4.7.0/snos/lib64",
      "-Wl,-rpath,/opt/cray/netcdf/4.2.0/gnu/47/lib",
      "-Wl,-rpath,#{udunits.prefix}/lib",
      "-Wl,-rpath,#{gsl.prefix}/lib"
    ].join(" ")

    system "UDUNITS2_PATH=#{udunits.prefix}",
           "HDF5_ROOT=$HDF5_DIR",
           "NETCDF4_ROOT=$NETCDF_DIR",
           "NETCDF_INC=$NETCDF_DIR/include",
           "NETCDF_LIB=$NETCDF_DIR/lib",
           "ANTLR_ROOT=#{antlr2.prefix}",
           "./configure --prefix=#{prefix}",
           "--disable-shared",
           "--enable-netcdf4",
           "--disable-udunits",
           "--enable-udunits2"
    system "make"
    system "make install"
  end
end
