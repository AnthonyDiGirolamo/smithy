Feature: View help documentation

  Scenario: View all help messages
    When I successfully run `smithy help`
    Then the stdout should contain "--help"
    When I successfully run `smithy help build`
    Then the stdout should contain "build [command options]"
    When I successfully run `smithy help search`
    Then the stdout should contain "search [command options]"
    When I successfully run `smithy help new`
    Then the stdout should contain "new [command options]"
