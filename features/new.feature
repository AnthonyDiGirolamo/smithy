Feature: Add new software builds
  As a tired staff member
  I should be able to create new software builds in /sw
  In as few steps as possible

  Background:
    Given my hostname is "awesome_sauce"
    And a software root in "/tmp/swsmithy" exists
    And an architecture folder named "x86" exists
    And my config file contains:
      """
      ---
      software-root: /tmp/swsmithy
      file-group-name: ccsstaff
      hostname-architectures:
        awesome_sauce: x86
      """

  Scenario: Add a new software build
    When I successfully run `smithy new git/1.6/build1`
    Then the stdout should contain "/tmp/swsmithy/x86/git/1.6/build1"
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/rebuild" should exist
		And a file named "/tmp/swsmithy/x86/git/1.6/build1/rebuild" should be group writable
		And a file named "/tmp/swsmithy/x86/git/1.6/build1/rebuild" should have a group name of "ccsstaff"
		And a file named "/tmp/swsmithy/x86/git/1.6/build1/rebuild" should be executable
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/remodule" should exist
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/retest" should exist
    And a file named "/tmp/swsmithy/x86/git/1.6/modulefile/git/1.6" should exist
    When I successfully run `diff -q /tmp/swsmithy/x86/git/1.6/build1/rebuild ../../etc/templates/build/rebuild`
    Then the stdout should not contain "Files /tmp/swsmithy/x86/git/1.6/build1/rebuild and etc/templates/build/retest differ"

  Scenario: Add a new software build without a web description
    When I successfully run `smithy new git/1.6/build2`
    Then the stdout should contain "/tmp/swsmithy/x86/git/1.6/build2"
    And a file named "/tmp/swsmithy/x86/git/description" should not exist

  Scenario: Add a new software build without a modulefile
    When I successfully run `smithy new --skip-modulefile cool_package/1.0/build1`
    Then the stdout should contain "/tmp/swsmithy/x86/cool_package/1.0/build1"
    And a file named "/tmp/swsmithy/x86/cool_package/1.0/modulefile" should not exist

  Scenario: Add a new software build with a web metadata
    When I successfully run `smithy new --web-description git/1.6/build3`
    Then the stdout should contain "/tmp/swsmithy/x86/git/1.6/build3"
    And a directory named "/tmp/swsmithy/x86/git/1.6/build3" should exist
    And a file named "/tmp/swsmithy/x86/git/description" should exist

	Scenario: Add a new software build with a source tarball
		When I successfully run `smithy new --tarball=../../zlib-1.2.6.tar.gz zlib/1.2.6/build1`
		Then a directory named "/tmp/swsmithy/x86/zlib/1.2.6/build1/source" should exist
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build1/source/configure" should exist
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build1/source/configure" should be group writable
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build1/source/configure" should have a group name of "ccsstaff"

	Scenario: Add a new software build with disabled group permissions
		When I successfully run `smithy --disable-group-writable new --tarball=../../zlib-1.2.6.tar.gz zlib/1.2.6/build2`
		Then a directory named "/tmp/swsmithy/x86/zlib/1.2.6/build2/source" should exist
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build2/source/configure" should exist
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build2/source/configure" should not be group writable
		And a file named "/tmp/swsmithy/x86/zlib/1.2.6/build2/source/configure" should have a group name of "ccsstaff"
