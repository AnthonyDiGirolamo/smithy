Feature: Add new software builds

  Background:
    Given my hostname is "awesome_sauce"
    #Given an empty software root in "/tmp/swsmithy"
    #And my architecture is set to "x86-test"
    And my config file contains:
      """
      ---
      :"hostname-architectures":
        awesome_sauce: x86-test
      :"software-root": /tmp/swsmithy
      :"file-group-name": ccsstaff
      :"file-bit-mask": 020
      """

  Scenario: Add a new software build
    When I successfully run `smithy --arch=x86-test --software-root=/tmp/swsmithy new --web-description git/1.6/sles11.1_gnu4.3.4`
    Then a directory named "/tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4" should exist
    And the stdout should contain "/tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4"
    And a file named "/tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4/rebuild" should exist
    And a file named "/tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4/remodule" should exist
    And a file named "/tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4/retest" should exist
    When I successfully run `diff -q /tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4/rebuild ../../etc/templates/build/rebuild`
    Then the stdout should not contain "Files /tmp/swsmithy/x86-test/git/1.6/sles11.1_gnu4.3.4/rebuild and etc/templates/build/retest differ"

