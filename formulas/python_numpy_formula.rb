class PythonNumpyFormula < Formula
  homepage "http://www.numpy.org/"
  url "http://downloads.sourceforge.net/project/numpy/NumPy/1.7.1/numpy-1.7.1.tar.gz"

  depends_on do
    packages = [ "cblas/20110120/sles11.1_gnu4.7.2_acml5.2.0" ]
    case build_name
    when /python3.3/
      packages << "python/3.3.0"
    when /python2.7/
      packages << "python/2.7.3"
    when /python2.6/
    end
    packages
  end

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
    m << "unload python"

    case build_name
    when /python3.3/
      m << "load python/3.3.0"
    when /python2.7/
      m << "load python/2.7.3"
    end
    m
  end

  def install
    module_list

    acml_prefix = "/opt/acml/5.2.0/gfortran64"

    FileUtils.mkdir_p "#{prefix}/lib"
    FileUtils.cp "#{cblas.prefix}/lib/libcblas.a", "#{prefix}/lib", verbose: true
    FileUtils.cp "#{acml_prefix}/lib/libacml.a",   "#{prefix}/lib", verbose: true
    FileUtils.cp "#{acml_prefix}/lib/libacml.so",  "#{prefix}/lib", verbose: true

    ENV['CC']  = 'gcc'
    ENV['CXX'] = 'g++'
    ENV['OPT'] = '-O3 -funroll-all-loops'

    patch <<-EOF.strip_heredoc
      diff --git a/site.cfg b/site.cfg
      new file mode 100644
      index 0000000..c7a4c65
      --- /dev/null
      +++ b/site.cfg
      @@ -0,0 +1,15 @@
      +[blas]
      +blas_libs = cblas, acml
      +library_dirs = #{prefix}/lib
      +include_dirs = #{cblas.prefix}/include
      +
      +[lapack]
      +language = f77
      +lapack_libs = acml
      +library_dirs = #{acml_prefix}/lib
      +include_dirs = #{acml_prefix}/include
      +
      +[fftw]
      +libraries = fftw3
      +library_dirs = /opt/fftw/3.3.0.1/x86_64/lib
      +include_dirs = /opt/fftw/3.3.0.1/x86_64/include
    EOF

    system "cat site.cfg"

    python_binary = "python"
    libdirs = []
    case build_name
    when /python3.3/
      python_binary = "python3.3"
      libdirs << "#{prefix}/lib/python3.3/site-packages"
    when /python2.7/
      libdirs << "#{prefix}/lib/python2.7/site-packages"
    when /python2.6/
      libdirs << "#{prefix}/lib64/python2.6/site-packages"
    end
    FileUtils.mkdir_p libdirs.first

    system "PYTHONPATH=$PYTHONPATH:#{libdirs.join(":")} #{python_binary} setup.py build"
    system "PYTHONPATH=$PYTHONPATH:#{libdirs.join(":")} #{python_binary} setup.py install --prefix=#{prefix} --compile"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    if [ is-loaded python/3.3.0 ] {
      set BUILD sles11.1_python3.3.0_gnu4.7.2_acml5.2.0
      set LIBDIR python3.3
    } elseif { [ is-loaded python/2.7.3 ] || [ is-loaded python/2.7.2 ] } {
      set BUILD sles11.1_python2.7.3_gnu4.7.2_acml5.2.0
      set LIBDIR python2.7
    } else {
      set BUILD sles11.1_python2.6.8_gnu4.7.2_acml5.2.0
      set LIBDIR python2.6
    }
    set PREFIX <%= @package.version_directory %>/$BUILD

    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path LD_LIBRARY_PATH $PREFIX/lib64
    prepend-path LD_LIBRARY_PATH /opt/gcc/4.7.2/snos/lib64
    prepend-path MANPATH         $PREFIX/share/man
    prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
  MODULEFILE
end
