class MagmaFormula < Formula
  homepage "http://icl.cs.utk.edu/magma/index.html"
  url "http://icl.cs.utk.edu/projectsfiles/magma/pubs/magma-1.3.0.tar.gz"

  depends_on ["cblas/20110120/cle4.0_gnu4.7.2_acml5.2.0"]

  modules ["PrgEnv-gnu", "cudatoolkit"]

  def install
    module_list

    patch <<-EOF.strip_heredoc
      diff --git a/make.inc b/make.inc
      new file mode 100644
      index 0000000..8b8cd6a
      --- /dev/null
      +++ b/make.inc
      @@ -0,0 +1,16 @@
      +GPU_TARGET = Fermi
      +CC        = gcc -DCUBLAS_GFORTRAN
      +NVCC      = nvcc
      +FORT      = gfortran -DCUBLAS_GFORTRAN
      +ARCH      = ar
      +ARCHFLAGS = cr
      +RANLIB    = ranlib
      +OPTS      = -O3 -DADD_ -fPIC
      +F77OPTS   = -O3 -DADD_ -fno-second-underscore
      +FOPTS     = -O3 -DADD_ -fno-second-underscore
      +NVOPTS    = -O3 -DADD_ --compiler-options -fno-strict-aliasing -DUNIX
      +LDOPTS    = -fPIC -Xlinker -zmuldefs
      +LIB       = -lacml -lpthread -lcublas -lm -lcblas
      +CUDADIR   = $(CRAY_CUDATOOLKIT_DIR)
      +LIBDIR    = -L/opt/acml/5.2.0/gfortran64/lib/ -L/sw/xk6/cblas/20110120/cle4.0_gnu4.7.2_acml5.2.0/lib -L$(CUDADIR)/lib64
      +INC       = -I$(CUDADIR)/include
    EOF

    system "make"
    system "cd #{prefix} && cp -rv source/include source/lib ./"
  end
end
