Feature: User API

  Scenario Outline: Get user by ID <userId>
    * def result = call read('classpath:common/get-user.feature') { userId: <userId> }
    * match result.responseStatus == 200
    * match result.response.name == '#string'

    Examples:
      | userId |
      | 1      |
      | 2      |
      | 3      |
