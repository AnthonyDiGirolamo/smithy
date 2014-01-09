Short Abstract
--------------

## Improving Software Installation Techniques at the Oak Ridge Leadership Facility: The Smithy software installation tool.

Smithy is a software compilation and installation tool that borrows ideas
heavily from the homebrew package management system for Mac OS X and SWTools.

Smithy is designed to sanely manage many software builds within an HPC Linux
environment using modulefiles to load software into a user's shell.

SWTools has set very good conventions for software installations at the OLCF.
Smithy's goal is to make following the SWtools conventions easier and less error
prone.

Smithy improves upon SWTools by providing a simpler command line interface,
modulefile generation and management, and installations via formulas written in
Ruby similar to homebrew.

The goal of installation formulas is to consolidate all knowledge required to
build a software package on any system into a single file. This can include:
defining dependencies, loading or swapping modules, setting environment
variables, applying patches, creating or changing makefiles, running the
compilation, running tests, and defining a modulefile.

Long Abstract
-------------

Smithy is a software compilation and installation tool that borrows ideas
heavily from the homebrew package management system for Mac OS X and SWTools.

Smithy is designed to sanely manage many software builds within an HPC Linux
environment using modulefiles to load software into a user's shell.

SWTools has set very good conventions for software installations at the OLCF.
Smithy's goal is to make following the SWtools conventions easier and less error
prone.

Smithy improves upon SWTools by providing a simpler command line interface,
modulefile generation and management, and installations via formulas written in
Ruby similar to homebrew.

SWTools relied on build scripts to perform installations. The problem with build
scripts is that they are duplicated for every software installation. This makes
installing new software tedious since one has to go back and look at existing
build scripts and copy relevant steps to a new build script.

Build scripts often simply run the default configure, make, install pattern and
thus custom changes to Makefiles or source code are not captured and become
difficult to replicate and maintain.

The goal of installation formulas is to consolidate all knowledge required to
build a software package on any system into a single file. This removes the
problem of duplicate build scripts. Formulas can include: defining dependencies,
loading or swapping modules, setting environment variables, applying patches,
creating or changing makefiles, running the compilation, running tests, and
defining a modulefile.

It is recommended that formulas be stored in a version control system such as
git or subversion. The OLCF uses github.com to store a repository with all its
formulas. This allows for easy sharing and collaboration with the HPC community.
New formulas or changing existing ones can be sent as a pull request between
HPC centers.

Smithy provides detailed documentation in manpages and on its website.
Additionally any Smithy subcommand can be prefixed with 'help' on the command
line to show all relevant options and arguments. There is also command line tab
completion for bash and zsh.

Documentation for installed software can be now written in markdown or html.
Under the SWTools scheme, installing the same package on multiple systems would
require separate documentation for each installation. Smithy adds an option to
use only one documentation file per software package across all systems.



---

Once a formula is written it is easy to see everything required to build a given
piece of software. Reproducing those steps is as simple as running one command.

- cleaner, shorter, and more maintainable codebase (about 1/2 the lines of code in swtools)
- simpler command line interface
- simpler and shorter rebuild scripts
- automatic generation of modulefiles
- automatic generation of scripts depending on the environment or compiler
- write software descriptions without html
- search for software, report who built it, and when

