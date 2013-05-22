class IpythonFormula < Formula
  homepage "http://ipython.org/"
  url "https://github.com/downloads/ipython/ipython/ipython-0.13.1.tar.gz"

  depends_on "python"

  modules do
    if build_name.include?("python3.3.0")
      [ "python/3.3.0" ]
    elsif build_name.include?("python2.7.3")
      [ "python/2.7.3" ]
    end
  end

  def install
    module_list
    python_binary = "python"
    if build_name.include?("python3.3.0")
      libdir = "#{prefix}/lib/python3.3/site-packages"
      FileUtils.mkdir_p libdir
      python_binary = "PYTHONPATH=$PYTHONPATH:#{libdir} python3.3"
    end
    system "#{python_binary} setup.py install --prefix=#{prefix} --compile"
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
      set BUILD sles11.1_gnu4.3.4_python3.3.0
      set LIBDIR python3.3
    } elseif { [ is-loaded python/2.7.3 ] || [ is-loaded python/2.7.2 ] } {
      set BUILD sles11.1_gnu4.3.4_python2.7.3
      set LIBDIR python2.7
    } else {
      set BUILD sles11.1_gnu4.3.4_python2.6.8
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
