Feature: Create description files
  Having installed software
  I should be able to create descriptions
  For users to read

  Background:
    Given a software root in "/tmp/swsmithy" exists
    And an architecture folder named "x86-64" exists
    And an architecture folder named "i686" exists

  Scenario: Create a description file in an application directory
    Given my hostname is "awesome_sauce"
    And my config file contains:
      """
      ---
      software-root: /tmp/swsmithy
      file-group-name: ccsstaff
      hostname-architectures:
        awesome_sauce: x86-64
        smarty_pants: i686
      """
    When I successfully run `smithy new --web-description zlib/1.2.6/build1`
    Then a file named "/tmp/swsmithy/x86-64/zlib/description.markdown" should exist

  Scenario: Create a description file in a common directory
    Given my hostname is "smarty_pants"
    And my config file contains:
      """
      ---
      software-root: /tmp/swsmithy
      file-group-name: ccsstaff
      hostname-architectures:
        awesome_sauce: x86-64
        smarty_pants: i686
      descriptions-root: /tmp/swsmithy/descriptions
      """
    When I successfully run `smithy new --web-description zlib/1.2.6/build1`
    Then a file named "/tmp/swsmithy/descriptions/zlib/description.markdown" should exist
    And a symlink named "/tmp/swsmithy/i686/zlib/description.markdown" should exist

