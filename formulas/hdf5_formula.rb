class Hdf5Formula < Formula
  homepage "http://www.hdfgroup.org/"
  url "http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.11.tar.gz"
  md5 "1a4cc04f7dbe34e072ddcf3325717504"

  depends_on "szip"

  module_commands do
    m = [ "unload PrgEnv-gnu PrgEnv-pgi PrgEnv-cray PrgEnv-intel" ]
    case build_name
    when /gnu/
      m << "load PrgEnv-gnu"
    when /pgi/
      m << "load PrgEnv-pgi"
    when /intel/
      m << "load PrgEnv-intel"
    when /cray/
      m << "load PrgEnv-cray"
    end
    m << "load szip"
    m << "swap xtpe-interlagos xtpe-istanbul"
    # m << "swap xtpe-interlagos xtpe-target-native"
  end

  def install
    module_list

    case build_name
    when /gnu/
      ENV["CC"]  = "gcc"
      ENV["CXX"] = "g++"
      ENV["F77"] = "gfortran"
      ENV["FC"]  = "gfortran"
      ENV["F9X"] = "gfortran"
    when /pgi/
      ENV["CC"]  = "pgcc"
      ENV["CXX"] = "pgCC"
      ENV["F77"] = "pgf77"
      ENV["FC"]  = "pgf90"
      ENV["F9X"]  = "pgf90"
    when /intel/
      ENV["CC"]  = "icc"
      ENV["CXX"] = "icpc"
      ENV["F77"] = "ifort"
      ENV["FC"]  = "ifort"
      ENV["F9X"]  = "ifort"
    # when /cray/
    #   ENV["CC"]  = "cc --target=native"
    #   ENV["CXX"] = "CC --target=native"
    #   ENV["F77"] = "ftn --target=native"
    #   ENV["FC"]  = "ftn --target=native"
    #   ENV["F9X"] = "ftn --target=native"
    end

    system "./configure --prefix=#{prefix}",
      "--with-zlib=/usr",
      "--with-szlib=$SZIP_DIR",
      "--enable-fortran",
      "--enable-cxx",
      "--enable-static",
      "--disable-shared"
    system "make"
    system "make install"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
      puts stderr {Sets up environment to use serial HDF5.

    Usage: ftn test.f90 \${HDF5_LIB} OR h5fc test.f90
    or     cc  test.c   \${HDF5_LIB} OR h5cc test.c

    The hdf5 module must be reloaded if you change the PrgEnv
    or you must issue a 'module update' command.

    **Note** Requires szip/2.1

    Loading the module:
      module load szip/2.1
      module load hdf5/1.8.11}
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    prereq szip/2.1
    set szipdir $::env(SZIP_DIR)

    <% if @builds.size > 1 %>
    <%= module_build_list @package, @builds %>

    set PREFIX <%= @package.version_directory %>/$BUILD
    <% else %>
    set PREFIX <%= @package.prefix %>
    <% end %>

    setenv HDF5_INCLUDE_PATH "-I$PREFIX/include"
    setenv HDF5_LIB "-L$PREFIX/lib -lhdf5_hl -lhdf5 -L$szipdir -lsz -lz -lm"
    setenv HDF5_DIR "${PREFIX}"

    prepend-path PATH             $PREFIX/bin
    prepend-path LD_LIBRARY_PATH  $PREFIX/lib
    prepend-path LIBRARY_PATH     $PREFIX/lib
    prepend-path INCLUDE_PATH     $PREFIX/include
  MODULEFILE
end
