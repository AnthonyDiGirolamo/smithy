class BoostFormula < Formula
  homepage "http://www.boost.org/"
  url      "http://downloads.sourceforge.net/project/boost/boost/1.53.0/boost_1_53_0.tar.bz2"
  sha256   "f88a041b01882b0c9c5c05b39603ec8383fb881f772f6f9e6e6fd0e0cddb9196"

  depends_on [ "bzip2" ]

  module_commands do
    m = [ "unload PrgEnv-gnu PrgEnv-pgi PrgEnv-cray PrgEnv-intel" ]
    case build_name
    when /gnu/
      m << "load PrgEnv-gnu"
    when /pgi/
      m << "load PrgEnv-pgi"
    end
  end

  def install
    module_list

    case build_name
    when /gnu/
      toolset="gcc"

      File.open("tools/build/v2/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using gcc
            : 4.7.2.xk7
            : CC
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
          ;
          using mpi
            : CC
            : <find-shared-library>mpich
            : aprun -n
          ;
        EOF
      end
    when /pgi/
      toolset="pgi"

      # Boost Ticket: https://svn.boost.org/trac/boost/ticket/8333
      patch <<-EOF.strip_heredoc
        diff --git a/boost/math/special_functions/sinc.hpp b/boost/math/special_functions/sinc.hpp
        index ffb19d8..8d2a8a6 100644
        --- a/boost/math/special_functions/sinc.hpp
        +++ b/boost/math/special_functions/sinc.hpp
        @@ -52,16 +52,7 @@ namespace boost
                 template<typename T>
                 inline T    sinc_pi_imp(const T x)
                 {
        -#if defined(BOOST_NO_STDC_NAMESPACE) && !defined(__SUNPRO_CC)
        -            using    ::abs;
        -            using    ::sin;
        -            using    ::sqrt;
        -#else    /* BOOST_NO_STDC_NAMESPACE */
        -            using    ::std::abs;
        -            using    ::std::sin;
        -            using    ::std::sqrt;
        -#endif    /* BOOST_NO_STDC_NAMESPACE */
        -
        +BOOST_MATH_STD_USING
                     // Note: this code is *not* thread safe!
                     static T const    taylor_0_bound = tools::epsilon<T>();
                     static T const    taylor_2_bound = sqrt(taylor_0_bound);
      EOF

      # Boost Ticket: https://svn.boost.org/trac/boost/ticket/8394
      patch <<-EOF.strip_heredoc
        diff -ur boost_1_53_0/libs/mpi/src/python/py_environment.cpp boost_1_53_0.2/libs/mpi/src/python/py_environment.cpp
        --- boost_1_53_0/libs/mpi/src/python/py_environment.cpp 2007-11-25 12:38:02.000000000 -0600
        +++ boost_1_53_0.2/libs/mpi/src/python/py_environment.cpp       2013-04-04 10:16:05.000000000 -0500
        @@ -31,7 +31,7 @@
          */
         static environment* env;

        -bool mpi_init(list python_argv, bool abort_on_exception)
        +bool mpi_init(boost::python::list python_argv, bool abort_on_exception)
         {
           // If MPI is already initialized, do nothing.
           if (environment::initialized())
        @@ -79,7 +79,7 @@
           if (!environment::initialized()) {
             // MPI_Init from sys.argv
             object sys = object(handle<>(PyImport_ImportModule("sys")));
        -    mpi_init(extract<list>(sys.attr("argv")), true);
        +    mpi_init(extract<boost::python::list>(sys.attr("argv")), true);

             // Setup MPI_Finalize call when the program exits
             object atexit = object(handle<>(PyImport_ImportModule("atexit")));
      EOF

      File.open("tools/build/v2/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using pgi
            : 13.3.0.xk7
            : pgCC
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
              <compileflags>-mp
          ;
          using mpi
            : pgCC
            : <find-shared-library>mpich_pgi
            : aprun -n
          ;
        EOF
      end
    end

    system "./bootstrap.sh --with-toolset=#{toolset} --prefix=#{prefix}"
    # system "./b2 toolset=#{toolset} link=static --clean"
    system "./b2 toolset=#{toolset} link=static --debug-configuration install"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
      puts stderr "<%= @package.name %> <%= @package.version %>"
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    <% if @builds.size > 1 %>
    <%= module_build_list @package, @builds %>

    set PREFIX <%= @package.version_directory %>/$BUILD
    <% else %>
    set PREFIX <%= @package.prefix %>
    <% end %>

    setenv BOOST_DIR   $PREFIX
    set    BOOST_LIB   "-L$PREFIX/lib"
    set    BOOST_INC   "-I$PREFIX/include"

    setenv BOOST_LIB   $BOOST_LIB
    setenv BOOST_INC   $BOOST_INC
    setenv BOOST_FLAGS "$BOOST_INC $BOOST_LIB"
  MODULEFILE
end
