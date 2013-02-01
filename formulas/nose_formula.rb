class NoseFormula < Formula
  homepage "https://nose.readthedocs.org/en/latest"
  url "http://pypi.python.org/packages/source/n/nose/nose-1.2.1.tar.gz"

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

    python_binary_name = "python"
    python_binary_name = "python3.3" if build_name.include?("python3.3.0")

    system "which #{python_binary_name}"

    system "PYTHONPATH=$PYTHONPATH:#{prefix}/lib/python3.3/site-packages #{python_binary_name} setup.py install --prefix=#{prefix} --compile"
  end
end
