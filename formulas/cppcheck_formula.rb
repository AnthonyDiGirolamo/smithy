class CppcheckFormula < Formula
  homepage "http://cppcheck.sourceforge.net/"
  url      "https://github.com/danmar/cppcheck/archive/1.57.zip"

  depends_on "pcre"

  def install
    module_list
    system "which gcc"

    ENV["PREFIX"] = prefix
    ENV["LDFLAGS"] = "-Wl,-rpath,#{pcre.prefix}/lib"
    system "export PATH=#{pcre.prefix}/bin:$PATH ; make HAVE_RULES=yes"
    system "make install"
  end
end
