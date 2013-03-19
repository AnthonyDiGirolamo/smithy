class NcoFormula < Formula
  homepage "http://nco.sourceforge.net/"
  url "http://nco.sourceforge.net/src/nco-4.2.5.tar.gz"
  md5 "8bb89217ac1dadb62679d1b08ea19025"

  modules ["PrgEnv-gnu", "netcdf", "hdf5", "gsl"]

  depends_on ["udunits", "gsl", "expat"]

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
           "./configure --prefix=#{prefix}",
           "--disable-shared",
           "--enable-netcdf4",
           "--disable-udunits",
           "--enable-udunits2",
           "--disable-ncap2"
    system "make"
    system "make install"
  end
end
