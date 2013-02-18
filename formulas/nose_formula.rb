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

    patch <<-EOF.strip_heredoc
    diff --git a/setup.py b/setup_fix.py
    index 43c3e4a..4323499 100644
    --- a/setup.py
    +++ b/setup_fix.py
    @@ -68,7 +68,7 @@ try:
     except ImportError:
         from distutils.core import setup
         addl_args = dict(
    -        packages = ['nose', 'nose.ext', 'nose.plugins', 'nose.sphinx'],
    +        packages = ['nose', 'nose.ext', 'nose.plugins', 'nose.sphinx', 'nose.tools'],
             scripts = ['bin/nosetests'],
             )

    EOF

    python_binary = "python"
    python_binary = "python3.3" if build_name.include?("python3.3.0")

    system "which #{python_binary}"

    system "PYTHONPATH=$PYTHONPATH:#{prefix}/lib/python3.3/site-packages #{python_binary} setup.py install --prefix=#{prefix} --compile"
  end
end
