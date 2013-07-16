class PythonMpi4pyFormula < Formula
  homepage "http://www.mpi4py.scipy.org/"
  url "https://mpi4py.googlecode.com/files/mpi4py-1.3.tar.gz"
  sha1 "282c1b9e35b242c9bd86126ebc5af6c70d8c2833"

  depends_on do
    packages = [ ]
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
    m = [ "unload PrgEnv-gnu PrgEnv-pgi PrgEnv-intel" ]
    m << "load PrgEnv-gnu"
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

    File.open("mpi.cfg", "w+") do |f|
      f.write <<-EOF.strip_heredoc
        [cray]
        mpi_dir = /opt/cray/mpt/5.6.3/gni/mpich2-gnu/47
        mpicc   = cc
        mpicxx  = CC
      EOF
    end

    ENV["XTPE_LINK_TYPE"] = "dynamic"

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

    python_start_command = "PYTHONPATH=$PYTHONPATH:#{libdirs.join(":")} #{python_binary} "

    system "#{python_start_command} setup.py build --mpi=cray"
    system "#{python_start_command} setup.py install --prefix=#{prefix} --compile"
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
      set BUILD python3.3.0
      set LIBDIR python3.3
    } elseif { [ is-loaded python/2.7.3 ] || [ is-loaded python/2.7.2 ] } {
      set BUILD python2.7.3
      set LIBDIR python2.7
    } else {
      set BUILD python2.6.8
      set LIBDIR python2.6
    }
    set PREFIX <%= @package.version_directory %>/$BUILD

    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path LD_LIBRARY_PATH $PREFIX/lib64
    prepend-path MANPATH         $PREFIX/share/man
    prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
  MODULEFILE
end
