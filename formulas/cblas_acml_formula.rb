class CblasAcmlFormula < Formula
  homepage "http://www.netlib.org/blas/"
  url      "http://www.netlib.org/blas/blast-forum/cblas.tgz"

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
    m << "load acml"
  end

  def install
    FileUtils.rm_f "Makefile.in"

    patch <<-EOF.strip_heredoc
      diff --git a/Makefile.in b/Makefile.in
      new file mode 100644
      index 0000000..1235d4b
      --- /dev/null
      +++ b/Makefile.in
      @@ -0,0 +1,12 @@
      +SHELL = /bin/sh
      +PLAT = LINUX
      +BLLIB = /opt/acml/5.2.0/gfortran64/lib/libacml.a
      +CBLIB = /sw/xk6/cblas/20110120/sles11.1_gnu4.7.2_acml5.2.0/lib/libcblas.a
      +CC = gcc
      +FC = gfortran
      +LOADER = $(FC)
      +CFLAGS = -O3 -DADD_
      +FFLAGS = -O3
      +ARCH = ar
      +ARCHFLAGS = r
      +RANLIB = ranlib
    EOF

    system "cat Makefile.in"
    system "make clean"
    FileUtils.mkdir_p "#{prefix}/lib"
    system "make all"
    FileUtils.cp_r "include", prefix
  end
end
