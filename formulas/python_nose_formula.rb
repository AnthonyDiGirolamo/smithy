class PythonNoseFormula < Formula
  homepage "https://nose.readthedocs.org/en/latest"
  url "https://pypi.python.org/packages/source/n/nose/nose-1.3.0.tar.gz"

  depends_on do
    case build_name
    when /python3.3/
      [ "python/3.3.0" ]
    when /python2.7/
      [ "python/2.7.3" ]
    when /python2.6/
      [ ]
    end
  end


  modules do
    case build_name
    when /python3.3/
      [ "python/3.3.0" ]
    when /python2.7/
      [ "python/2.7.3" ]
    end
  end

  def install
    module_list

# Is this needed?
#    patch <<-EOF.strip_heredoc
#    diff --git a/setup.py b/setup_fix.py
#    index 43c3e4a..4323499 100644
#    --- a/setup.py
#    +++ b/setup_fix.py
#    @@ -68,7 +68,7 @@ try:
#     except ImportError:
#         from distutils.core import setup
#         addl_args = dict(
#    -        packages = ['nose', 'nose.ext', 'nose.plugins', 'nose.sphinx'],
#    +        packages = ['nose', 'nose.ext', 'nose.plugins', 'nose.sphinx', 'nose.tools'],
#             scripts = ['bin/nosetests'],
#             )
#
#    EOF

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
