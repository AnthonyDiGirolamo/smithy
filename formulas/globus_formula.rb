class GlobusFormula < Formula
  homepage "http://www.globus.org/toolkit/"
  url "http://www.globus.org/ftppub/gt5/5.2/5.2.4/installers/src/gt5.2.4-all-source-installer.tar.gz"
  md5 "78a844d7b25064fb285ae94cde56e30c"
  sha1 "7ee9dcc9804584b628d8f10938a4206b9221755f"

  def install
    module_list
    system "./configure --prefix=#{prefix} --with-gsiopensshargs=--with-pam"
    system "make"
    system "make globus_ftp_client_test-compile"
    system "make install"
    system "cd ./source-trees/gridftp/client/test/ && cp -v globus-ftp-client-cksm-test globus-ftp-client-mlst-test globus-ftp-client-modification-time-test globus-ftp-client-size-test globus-ftp-client-delete-test #{prefix}/bin/"
  end
end
