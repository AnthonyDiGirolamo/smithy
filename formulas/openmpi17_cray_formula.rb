class Openmpi17CrayFormula < Formula
  homepage "http://www.open-mpi.org"
  url      "http://www.open-mpi.org/software/ompi/v1.7/downloads/openmpi-1.7.1.tar.bz2"
  md5      "f25b446a9dcbbd6a105a99d926d34441"

  modules do
    if build_name =~ /gnu/
      ["DefApps", "PrgEnv-gnu", "gcc"]
    elsif build_name =~ /intel/
      ["DefApps", "PrgEnv-intel", "intel"]
    elsif build_name =~ /pgi/
      ["DefApps", "PrgEnv-pgi", "pgi"]
    end
  end

  def install
    if build_name =~ /gnu/
      ENV["CC"]  = "gcc"
      ENV["CXX"] = "g++"
      ENV["F77"] = "gfortran"
      ENV["FC"]  = "gfortran"
      ENV["CFLAGS"]   = "-march=amdfam10 -I/opt/cray/xe-sysroot/4.1.40/usr/include"
      ENV["CPPFLAGS"] = "-march=amdfam10 -I/opt/cray/xe-sysroot/4.1.40/usr/include"
    elsif build_name =~ /intel/
      ENV["CC"]  = "icc"
      ENV["CXX"] = "icpc"
      ENV["F77"] = "ifort"
      ENV["FC"]  = "ifort"
      ENV["CFLAGS"]   = "-I/opt/cray/xe-sysroot/4.1.40/usr/include"
      ENV["CPPFLAGS"] = "-I/opt/cray/xe-sysroot/4.1.40/usr/include"
    elsif build_name =~ /pgi/
      ENV["CC"]  = "pgcc"
      ENV["CXX"] = "pgCC"
      ENV["F77"] = "pgf77"
      ENV["FC"]  = "pgf90"
      ENV["CFLAGS"]   = "-I/opt/cray/xe-sysroot/4.1.40/usr/include"
      ENV["CPPFLAGS"] = "-I/opt/cray/xe-sysroot/4.1.40/usr/include"
    end
    module_list

    system "./configure --prefix=#{prefix}",
      "--enable-dlopen=no",
      "--enable-mem-debug=no",
      "--enable-mem-profile=no",
      "--enable-debug-symbols=no",
      "--enable-binaries=yes",
      "--enable-heterogeneous=no",
      "--enable-picky=no",
      "--enable-debug=no",
      "--enable-shared=yes",
      "--enable-orte-static-ports=no",
      "--enable-static=yes",
      "--enable-ipv6=no",
      "--enable-mpi-fortran=yes",
      "--enable-mpi-cxx=yes",
      "--enable-mpi-cxx-seek=yes",
      "--enable-cxx-exceptions=yes",
      "--enable-ft-thread=no",
      "--enable-per-user-config-files=no",
      "--enable-pty-support=no",
      "--enable-mca-no-build=carto,crs,filem,routed-linear,snapc,pml-dr,pml-crcp2,pml-crcpw,pml-v,pml-example,crcp,pml-cm,ess-cnos,grpcomm-cnos,plm-rsh,btl-tcp,oob-ud",
      "--enable-contrib-no-build=libnbc,vt",
      "--with-verbs=no",
      "--with-devel-headers=yes",
      "--with-alps=yes",
      "--with-xpmem=/opt/cray/xpmem/default",
      "--with-pmi=/opt/cray/pmi/default",
      "--with-cray-pmi2-ext=yes",
      "--with-ugni=/opt/cray/ugni/default",
      "--with-ugni-includedir=/opt/cray/gni-headers/default/include",
      "--with-tm=no",
      "--with-slurm=no",
      "--with-io-romio-flags=--with-file-system=ufs+nfs",
      "--with-memory-manager=ptmalloc2",
      "--with-valgrind=no"
      "--with-wrapper-cflags='-I/opt/cray/xe-sysroot/4.1.40/usr/include'"

    system "make"
    system "make install"
  end
end
