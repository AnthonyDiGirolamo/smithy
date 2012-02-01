Feature: Add new software builds

  Background:
    Given my hostname is "awesome_sauce"
    And an empty software root in "/tmp/swsmithy" exists
    And an architecture folder named "x86" exists
    And my config file contains:
      """
      ---
      software-root: /tmp/swsmithy
      file-group-name: ccsstaff
      hostname-architectures:
        awesome_sauce: x86
      """

  Scenario: Add a new software build without web metadata
    When I successfully run `smithy new git/1.6/build2`
    Then the stdout should contain "/tmp/swsmithy/x86/git/1.6/build2"
    And a file named "/tmp/swsmithy/x86/git/description" should not exist

  Scenario: Add a new software build with web metadata
    When I successfully run `smithy new --web-description git/1.6/build1`
    Then the stdout should contain "/tmp/swsmithy/x86/git/1.6/build1"
    And a directory named "/tmp/swsmithy/x86/git/1.6/build1" should exist
    And a file named "/tmp/swsmithy/x86/git/description" should exist
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/rebuild" should exist
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/remodule" should exist
    And a file named "/tmp/swsmithy/x86/git/1.6/build1/retest" should exist
    When I successfully run `diff -q /tmp/swsmithy/x86/git/1.6/build1/rebuild ../../etc/templates/build/rebuild`
    Then the stdout should not contain "Files /tmp/swsmithy/x86/git/1.6/build1/rebuild and etc/templates/build/retest differ"

