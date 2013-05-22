class PysqliteFormula < Formula
  homepage "http://code.google.com/p/pysqlite/"
  url "http://pysqlite.googlecode.com/files/pysqlite-2.6.3.tar.gz"
  sha1 "d74d7649c5a1e9fb19dfa78c28b163007468a8cf"

  depends_on ["python", "sqlite"]

  modules do
    if build_name.include?("python2.7.3")
      [ "python/2.7.3" ]
    end
  end

  def install
    module_list

    ENV["CFLAGS"]  = "-I#{sqlite.prefix}/include"
    ENV["LDFLAGS"] = "-L#{sqlite.prefix}/lib"

    system "python setup.py install --prefix=#{prefix} --compile"
  end
end
