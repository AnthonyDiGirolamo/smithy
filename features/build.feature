#Feature: Build software using an existing rebuild script

  #Background:
    #Given my hostname is "awesome_sauce"
    #And an empty software root in "/tmp/swsmithy" exists
    #And an architecture folder named "x86" exists
    #And my config file contains:
      #"""
      #---
      #software-root: /tmp/swsmithy
      #file-group-name: ccsstaff
      #hostname-architectures:
        #awesome_sauce: x86
      #"""

  #Scenario: Add a new software build
    ##When I successfully run `smithy new --web-description tree/1.5.2/build1`

