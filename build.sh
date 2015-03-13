#!/bin/bash
bundle exec ./bin/smithy _doc
bundle exec ronn --style='toc' man/man1/smithy.1.ronn man/man5/smithyformula.5.ronn
bundle exec rake rerdoc
rake package:linux:x86_64
