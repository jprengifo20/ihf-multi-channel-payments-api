@ignore
Feature: Reusable - get user by id

  Scenario:
    Given url baseUrl
    And path 'users', userId
    When method get
