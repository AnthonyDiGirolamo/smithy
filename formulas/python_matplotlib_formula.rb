class PythonMatplotlibFormula < Formula
  homepage "http://matplotlib.org/"
  url "https://downloads.sourceforge.net/project/matplotlib/matplotlib/matplotlib-1.2.1/matplotlib-1.2.1.tar.gz"

  depends_on do
    case build_name
    when /python3.3/
      [ "python/3.3.0", "python_numpy/1.7.1/sles11.1_python3.3.0_gnu4.7.2_acml5.2.0" ]
    when /python2.7/
      [ "python/2.7.3", "python_numpy/1.7.1/sles11.1_python2.7.3_gnu4.7.2_acml5.2.0" ]
    when /python2.6/
      [ "python_numpy/1.7.1/sles11.1_python2.6.8_gnu4.7.2_acml5.2.0" ]
    end
  end

  modules do
    case build_name
    when /python3.3/
      [ "python/3.3.0", "python_numpy/1.7.1" ]
    when /python2.7/
      [ "python/2.7.3", "python_numpy/1.7.1" ]
    when /python2.6/
      [ "python_numpy/1.7.1" ]
    end
  end

  def install
    module_list

    python_binary = "python"
    libdirs = []
    case build_name
    when /python3.3/
      python_binary = "python3.3"
      libdirs << "#{prefix}/lib/python3.3/site-packages"
      libdirs << "#{python_numpy.prefix}/lib/python3.3/site-packages"
    when /python2.7/
      libdirs << "#{prefix}/lib/python2.7/site-packages"
      libdirs << "#{python_numpy.prefix}/lib/python2.7/site-packages"
    when /python2.6/
      libdirs << "#{prefix}/lib64/python2.6/site-packages"
      libdirs << "#{python_numpy.prefix}/lib64/python2.6/site-packages"
    end
    FileUtils.mkdir_p libdirs.first

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
      set BUILD sles11.1_python3.3.0_numpy1.7.1
      set LIBDIR python3.3
    } elseif { [ is-loaded python/2.7.3 ] || [ is-loaded python/2.7.2 ] } {
      set BUILD sles11.1_python2.7.3_numpy1.7.1
      set LIBDIR python2.7
    } else {
      set BUILD sles11.1_python2.6.8_numpy1.7.1
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
