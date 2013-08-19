Smithy is a tool that aims to replicate and improve upon functionality of
[SWTools](http://www.olcf.ornl.gov/center-projects/swtools/).

Overview
========

More information and a tutorial can be found on the [manpage](http://anthonydigirolamo.github.com/smithy/smithy.1.html).

Features
========

Smithys goal is to make following the SWTools conventions easier and less error
prone. Improvements include:

- Simpler command line interface. You can compile a new piece of software with
  two commands.
- Simpler rebuild scripts (8 lines instead of 49).
- Automatic generation of modulefiles.
- Automatic generation of build scripts depending on the environment or
  compiler.
- Write software descriptions without html.
- Search for software, report who built it, and when.
- Cleaner, shorter, and more maintainable code.

Installation
============

Installing ruby
---------------

Smithy requires ruby 1.9.2 or later. Most distrubutions only ship version 1.8.7
and you may need build your own copy. The simplest way is using the excellent
[ruby-build](https://github.com/sstephenson/ruby-build) script. As an example,
this will install ruby with a prefix of `/sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4`

    curl -L https://github.com/sstephenson/ruby-build/archive/master.zip -o ruby-build.zip
    unzip ruby-build.zip
    cd ruby-build-master
    ./bin/ruby-build -h
    ./bin/ruby-build --definitions
    ./bin/ruby-build 1.9.3-p286 /sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4

Many sites use [Environment Modules](http://modules.sourceforge.net/) to allow
users to load and unload software into their environment. Here is sample
modulefile for ruby installed in the previous example.

    #%Module1.0
    proc ModulesHelp { } {
      puts stderr "Ruby 1.9.3 patch 286"
      puts stderr "The gem command will install gems to the ~/.gem directory."
    }
    module-whatis "Ruby 1.9.3-p286"

    set PREFIX /sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4
    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path MANPATH         $PREFIX/share/man
    setenv       GEM_HOME        $env(HOME)/.gem/ruby/1.9.1
    setenv       GEM_PATH        $env(HOME)/.gem/ruby/1.9.1:$PREFIX/lib/ruby/gems/1.9.1
    prepend-path PATH            $env(HOME)/.gem/ruby/1.9.1/bin:$PREFIX/lib/ruby/gems/1.9.1/bin

This file should be saved to `$MODULEPATH/ruby/1.9.3`

Installing smithy
-----------------

### Choosting an install location

There are two ways to install smithy. The simplest is by simply installing the
`software_smithy` gem. This will install smithy and it's required gems in
your home directory:

    gem install software_smithy

If you are installing in production for all users you will want to install
smithy somewhere everyone can access. There are two places you might want to do
this:

#### Ruby's default `GEM_PATH`

If you installed manually using the examples above, this will be something like
`PREFIX/lib/ruby/gems/1.9.1` This will give access to smithy whenever
ruby is loaded into a users environment using the modulefile above. To install
to ruby's default `GEM_PATH` (following the above example):

    export GEM_HOME=/sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4/lib/ruby/gems/1.9.1
    gem install software_smithy --no-rdoc --no-ri

#### A different location of your choosing.

This is useful if you want a single smithy install location for more than one
install of ruby (typically on separate machines). This method is a bit more
complicated and requires users to load smithy into their environment manually in
addition to ruby.

Assuming you use environment modules you can install smithy to a separate
directory e.g. `/sw/tools/smithy` with the
[install\_smithy](https://github.com/AnthonyDiGirolamo/smithy/blob/master/script/install_smithy)
script. This will setup a folder containing the smithy gem, a modulefile and a
script that sets up shell completion. Users can load smithy into their
environment by running:

    source /sw/tools/smithy/environment.sh

### Loading smithy into your environment

Smithy depends on a config file to define it's behavior. Once created you can
point smithy to it's location using the `$SMITHY_CONFIG` environment variable.

Here is an example config file:

    ---
    software-root: /sw
    file-group-name: ccsstaff
    hostname-architectures:
      titan-ext: xk6
      titan-login: xk6
      chester-login: xk6
      lens: analysis-x64
      lens-login: analysis-x64
      sith: redhat6
      sith-login: redhat6
      smoky: smoky
      smoky-login: smoky
    programming-environment-prefix:
      default: PrgEnv-
      smoky: PE-
      sith: PE-
    web-root: /ccs/proj/ccsstaff/swdesc/data
    descriptions-root: /sw/descriptions
    web-architecture-names:
      xk6: titan
      analysis-x64: lens
      smoky: smoky
    download-cache: /sw/sources
    formula-directories:
    - /sw/tools/smithy/formulas
    global-error-log: /sw/tools/smithy/exceptions.log

You may wish to set this using a modulefile or a shell script. Examples are
provided in
[modulefiles/smithy/1.1](https://github.com/AnthonyDiGirolamo/smithy/blob/master/modulefiles/smithy/1.1)
and
[environment.sh](https://github.com/AnthonyDiGirolamo/smithy/blob/master/environment.sh)

License
=======

Smithy is based on the ideas created in SWTools and uses a BSD license. See
[LICENSE](https://github.com/AnthonyDiGirolamo/smithy/blob/master/LICENSE) for
the exact text.

Contributing and Support
========================

The smithy [github repo](https://github.com/AnthonyDiGirolamo/smithy) contains
all development files. Please fork and send me a pull request with any additions
or changes.

If you encounter any issues please [open an issue](https://github.com/AnthonyDiGirolamo/smithy/issues) on github. Or send me an email.

