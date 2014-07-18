Feature: Interact with formulas

  Background:
    Given my hostname is "awesome_sauce"
    And a software root in "/tmp/swsmithy" exists
    And an architecture folder named "x86" exists
    And my config file contains:
      """
      ---
      software-root: /tmp/swsmithy
      hostname-architectures:
        awesome_sauce: x86
      """

  Scenario: List available formulas
    When I successfully run `smithy formula list`
    Then the stdout should contain "zlib"

  Scenario: Display formula
    When I successfully run `smithy formula display zlib`
    Then the stdout should contain "ZlibFormula"

  Scenario: Get file path of a formula
    When I successfully run `smithy formula which zlib`
    Then the stdout should contain "/zlib_formula.rb"

  Scenario: Install a formula with full name
    When I successfully run `smithy formula install zlib/1.2/fullpath`
    # Then show me the files
    Then the stdout should contain "==> ./configure --prefix=/tmp/swsmithy/x86/zlib/1.2/fullpath"
    Then the stdout should contain "==> make"
    Then the stdout should contain "==> make install"
    Then the stdout should contain "==> SUCCESS /tmp/swsmithy/x86/zlib/1.2/fullpath"
    And a directory named "/tmp/swsmithy/x86/zlib/1.2/fullpath" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2/fullpath/source" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2/fullpath/source/configure" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2/fullpath/lib" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2/fullpath/lib/libz.a" should exist

  Scenario: Install a formula using the formula name and version
    When I run `smithy formula install zlib/1.2.0` interactively
    And I type "y"
    # Then show me the files
    Then the stdout should contain "==> ./configure --prefix=/tmp/swsmithy/x86/zlib/1.2.0/x86_64"
    Then the stdout should contain "==> make"
    Then the stdout should contain "==> make install"
    Then the stdout should contain "==> SUCCESS /tmp/swsmithy/x86/zlib/1.2.0/x86_64"
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.0/x86_64" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.0/x86_64/source" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2.0/x86_64/source/configure" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.0/x86_64/lib" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2.0/x86_64/lib/libz.a" should exist

  Scenario: Install a formula using the formula name only
    When I run `smithy formula install zlib` interactively
    And I type "y"
    # Then show me the files
    Then the stdout should contain "==> ./configure --prefix=/tmp/swsmithy/x86/zlib/1.2.8/x86_64"
    Then the stdout should contain "==> make"
    Then the stdout should contain "==> SUCCESS /tmp/swsmithy/x86/zlib/1.2.8/x86_64"
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.8/x86_64" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.8/x86_64/source" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2.8/x86_64/source/configure" should exist
    And a directory named "/tmp/swsmithy/x86/zlib/1.2.8/x86_64/lib" should exist
    And a file named "/tmp/swsmithy/x86/zlib/1.2.8/x86_64/lib/libz.a" should exist

