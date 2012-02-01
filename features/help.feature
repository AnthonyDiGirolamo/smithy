Feature: View help documentation

  Scenario: Add a new software build
    When I successfully run `smithy help`
    Then the stdout should contain "--help"
