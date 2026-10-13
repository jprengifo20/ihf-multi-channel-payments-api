@regression
Feature: Anulación de pago BCP

  @ignore @name=annulment
  Scenario: Ejecutar anulación reutilizable
    * requireBcpConfiguration()
    * def customerId = requireEightDigitValue('customerId', customerId)
    * def operationNumber = requireEightDigitValue('operationNumber', operationNumber)
    * def rqUUID = java.util.UUID.randomUUID().toString()
    * def operationDate = nowWithoutZone()
    * def requestBody = read('classpath:financiera/bcp/requests/annulment.json')
    * def endpointUrl = bcpEndpoint('integrations/bcp/annulment')
    Given url endpointUrl
    And headers commonHeaders
    And header Authorization = bcpAuthorization()
    And request requestBody
    When method post
    Then status 200
    * print 'ANNULMENT customerId:', customerId, 'operationNumber:', operationNumber, 'resultCode:', response.resultCode
