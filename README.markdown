Smithy
======

This repo is for the Smithy application itself. For formulas see
[smithy_formulas](https://github.com/AnthonyDiGirolamo/smithy_formulas)

Overview
--------

`smithy` is a command line software installation tool that borrows ideas heavily
from the excellent [homebrew](http://brew.sh/) package management system for Mac
OS X and
[SWTools](http://www.olcf.ornl.gov/center-projects/swtools/).[<sup>1</sup>](#smithy_ref1)

Smithy is designed to sanely manage many software builds within a shared
[HPC](http://en.wikipedia.org/wiki/High-performance_computing) Linux or Mac
environment using [modulefiles](http://modules.sourceforge.net/) to load
software into a user's shell.

Software builds are created with a few conventions:

- Everything is organized into architecture or OS directores, e.g. redhat6 or sles11
- Prefixes are defined by their name, version, and build name
- Software is loaded into the shell using [modulefiles](http://modules.sourceforge.net/)
- Builds are performed by [formulas](http://anthonydigirolamo.github.io/smithy/smithy.1.html#FORMULAS) or [build scripts](http://anthonydigirolamo.github.io/smithy/smithy.1.html#BUILD-SCRIPTS)

Examples of many formulas can be found in the
[smithy_formulas](https://github.com/AnthonyDiGirolamo/smithy_formulas) repo.

Documentation
-------------

Lots of information and a tutorial can be found on the manpages:

* [smithy](http://anthonydigirolamo.github.com/smithy/smithy.1.html?2)

* [smithyformula](http://anthonydigirolamo.github.com/smithy/smithyformula.5.html?2)

Installation
------------

Smithy is available for download on the [releases
page](https://github.com/AnthonyDiGirolamo/smithy/releases). Once downloaded it
can be extracted and run from any location. Smithy is written in
[ruby](https://www.ruby-lang.org/) and provides a built in ruby environment via
[Traveling-Ruby](http://phusion.github.io/traveling-ruby/). You do not need to
install ruby to use Smithy. Releases for Mac and Linux are available.

Running
-------

Extract to a directory of your choice and set the `$SMITHY_PREFIX` environment
variable in the `environment.sh` file. Assuming you extracted Smithy to
`/sw/tools/smithy` the top of the environment.sh file should look like:

    export SMITHY_PREFIX=/sw/tools/smithy
    export SMITHY_CONFIG=$SMITHY_PREFIX/smithyrc
    export MANPATH=$SMITHY_PREFIX/lib/app/man:$MANPATH

Once set, source the `environment.sh` using `bash` or `zsh`

    source /sw/tools/smithy/environment.sh

Smithy depends on a config file to define it's behavior. Once created you can
point Smithy to it's location by setting the `$SMITHY_CONFIG` environment
variable.

You can generate an example config file using Smithy itself by running:

    smithy show example_config

Here is an example config file in [yaml](http://yaml.org/) format:

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

License
-------

Smithy is based on the ideas created in SWTools and uses a BSD license. See
[LICENSE](https://github.com/AnthonyDiGirolamo/smithy/blob/master/LICENSE) for
the exact text.

References
----------

<a name="smithy_ref1"></a>

<p>N. Jones, M. R. Fahey, "Design, Implementation, and Experiences of Third-Party Software Administration at the ORNL NCCS," Proceedings of the 50th Cray User Group (CUG08), Helsinki, May 2008.</p>

Contributing and Support
------------------------

The Smithy [github repo](https://github.com/AnthonyDiGirolamo/smithy) contains
all development files. Please fork and send me a pull request with any additions
or changes.

If you encounter any issues please [open an issue](https://github.com/AnthonyDiGirolamo/smithy/issues) on github. Or send me an email.

