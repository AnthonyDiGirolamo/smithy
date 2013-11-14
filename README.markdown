Software Smithy
===============

Overview
--------

`smithy` is a command line software installation/compilation tool that borrows
ideas heavily from the excellent [homebrew](http://brew.sh/) package management
system for Mac OS X and [SWTools](http://www.olcf.ornl.gov/center-projects/swtools/).[^1]

Smithy is designed to sanely manage many software builds within a
shared [HPC](http://en.wikipedia.org/wiki/High-performance_computing)
Linux environment using [modulefiles](http://modules.sourceforge.net/) to load
software into a user's shell.

Software builds are created with a few conventions:

- Everything is organized into architecture or OS directores, e.g. redhat6 or sles11
- Prefixes are defined by their name, version, and build name
- Software is loaded into the shell using [modulefiles](http://modules.sourceforge.net/)
- Builds are performed by [build scripts](http://anthonydigirolamo.github.io/smithy/smithy.1.html#BUILD-SCRIPTS) or [formulas](http://anthonydigirolamo.github.io/smithy/smithy.1.html#FORMULAS)

As an example:

    /opt                         Software Root
    ├── redhat6                    OS directory
    |   |
    |   ├── modulefiles                Modules live here
    |   |   ├── git                         Application
    |   |   |   ├── 1.7.8.5                     Versions
    |   |   |   └── 1.8.2.1
    |   |   └── petsc
    |   |       ├── 3.2
    |   |       └── 3.3
    |   |
    |   ├── git                        Application Name
    |   |   ├── 1.7.8.5                    Version
    |   |   |   └── rhel6.4_gnu4.4.7           Build Name
    |   |   └── 1.8.2.1
    |   |       └── rhel6.4_gnu4.4.7
    |   |
    |   └── petsc
    |       ├── 3.2
    |       |   ├── rhel6.4_pgi12.8            Build using PGI 12.8 compiler
    |       |   └── rhel6.4_gnu4.6.3           Build using GNU 4.6.3 compiler
    |       └── 3.3
    |           ├── rhel6.4_pgi12.8
    |           ├── rhel6.4_pgi13.4
    |           └── rhel6.4_gnu4.7.1
    |
    └── sles11                     Another OS directory
        |
        ├── modulefiles
        |   └── git
        |       ├── 1.7.8.5
        |       └── 1.8.2.1
        |
        └── git
            ├── 1.7.9.5
            |   └── sles11.1_gnu4.3.4
            └── 1.8.2.1
                └── sles11.1_gnu4.3.4

Documentation
-------------

Lots of information and a tutorial can be found on the manpages:

* [smithy](http://anthonydigirolamo.github.com/smithy/smithy.1.html)

* [smithyformula](http://anthonydigirolamo.github.com/smithy/smithyformula.5.html)

Installation
------------

smithy is available through [rubygems](http://rubygems.org/gems/software_smithy)
so if you already have ruby 1.9.2 or higher available just run:

    gem install software_smithy

Set `$SMITHY_CONFIG` to your smithy config file and you're good to go. If you
need to install ruby or require a multiuser installation read on:

### Installing ruby

Smithy requires ruby 1.9.2 or later. Most enterprise Linux distributions only
ship version 1.8.7 and you may need build your own copy. The simplest way is
using the excellent [ruby-build](https://github.com/sstephenson/ruby-build)
script. As an example, this will install ruby with a prefix of
`/sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4`

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

### Installing smithy

#### Choosting an install location

There are two ways to install smithy. The simplest is by simply installing the
`software_smithy` gem. This will install smithy and it's required gems in
your home directory:

    gem install software_smithy

If you are installing in production for all users you will want to install
smithy somewhere everyone can access. There are two places you might want to do
this:

##### Ruby's default `GEM_PATH`

If you installed manually using the examples above, this will be something like
`PREFIX/lib/ruby/gems/1.9.1` This will give access to smithy whenever
ruby is loaded into a users environment using the modulefile above. To install
to ruby's default `GEM_PATH` (following the above example):

    export GEM_HOME=/sw/xk6/ruby/1.9.3-p286/sles11.1_gnu4.3.4/lib/ruby/gems/1.9.1
    gem install software_smithy --no-rdoc --no-ri

##### A different location of your choosing.

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
[modulefiles/smithy/1.6](https://github.com/AnthonyDiGirolamo/smithy/blob/master/modulefiles/smithy/1.6.3)
and
[environment.sh](https://github.com/AnthonyDiGirolamo/smithy/blob/master/environment.sh)

License
-------

Smithy is based on the ideas created in SWTools and uses a BSD license. See
[LICENSE](https://github.com/AnthonyDiGirolamo/smithy/blob/master/LICENSE) for
the exact text.

References
----------

[^1]: N. Jones, M. R. Fahey, "Design, Implementation, and Experiences of Third-Party Software Administration at the ORNL NCCS," Proceedings of the 50th Cray User Group (CUG08), Helsinki, May 2008.

Contributing and Support
------------------------

The smithy [github repo](https://github.com/AnthonyDiGirolamo/smithy) contains
all development files. Please fork and send me a pull request with any additions
or changes.

If you encounter any issues please [open an issue](https://github.com/AnthonyDiGirolamo/smithy/issues) on github. Or send me an email.

