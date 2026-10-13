@regression
Feature: Pago BCP

  @ignore @name=payment
  Scenario: Ejecutar pago reutilizable
    * requireBcpConfiguration()
    * def customerId = requireEightDigitValue('customerId', customerId)
    * def operationNumber = requireEightDigitValue('operationNumber', operationNumber)
    * def rqUUID = java.util.UUID.randomUUID().toString()
    * def operationDate = nowWithoutZone()
    * def requestBody = read('classpath:financiera/bcp/requests/payment.json')
    * def endpointUrl = bcpEndpoint('integrations/bcp/payment')
    Given url endpointUrl
    And headers commonHeaders
    And header Authorization = bcpAuthorization()
    And request requestBody
    When method post
    Then status 200
    * print 'PAYMENT customerId:', customerId, 'operationNumber:', operationNumber, 'resultCode:', response.resultCode
