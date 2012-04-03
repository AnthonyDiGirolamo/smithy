Feature: View help documentation

  Scenario: View all help messages
    When I successfully run `smithy help`
    Then the stdout should contain "--help"
