#!/bin/bash
bundle exec smithy _doc
bundle exec ronn --style='toc' man/man1/smithy.1.ronn man/man5/smithyformula.5.ronn
bundle exec rake rerdoc
rake -f Rakefile_traveling_ruby package:linux:x86_64
