@regression
Feature: Consulta de deuda BCP

  @ignore @name=inquire
  Scenario: Ejecutar consulta de deuda reutilizable
    * requireBcpConfiguration()
    * def customerId = requireEightDigitValue('customerId', customerId)
    * def rqUUID = java.util.UUID.randomUUID().toString()
    * def requestBody = read('classpath:financiera/bcp/requests/inquire.json')
    * def endpointUrl = bcpEndpoint('integrations/bcp/inquire')
    Given url endpointUrl
    And headers commonHeaders
    And header Authorization = bcpAuthorization()
    And request requestBody
    When method post
    Then status 200
    * print 'INQUIRE customerId:', customerId, 'resultCode:', response.resultCode

  @ignore @name=inquireUntilDebtRestored
  Scenario: Reconsultar hasta que la deuda sea restituida
    * requireBcpConfiguration()
    * def customerId = requireEightDigitValue('customerId', customerId)
    * def rqUUID = java.util.UUID.randomUUID().toString()
    * def requestBody = read('classpath:financiera/bcp/requests/inquire.json')
    * configure retry = debtRestorationRetry
    * def endpointUrl = bcpEndpoint('integrations/bcp/inquire')
    Given url endpointUrl
    And headers commonHeaders
    And header Authorization = bcpAuthorization()
    And request requestBody
    And retry until response.resultCode == 'CP0000' && response.documents && response.documents.length > 0
    When method post
    Then status 200
    * print 'INQUIRE post-annulment customerId:', customerId, 'resultCode:', response.resultCode

  Scenario Outline: Consultar deuda para <caso>
    * def requestedCustomerId = '<dni>'
    * def inquiry = call read('classpath:financiera/bcp/inquire.feature@name=inquire') { customerId: '#(requestedCustomerId)' }
    * match inquiry.responseStatus == 200
    * match inquiry.response contains { rqUUID: '#regex ^[0-9a-fA-F-]{36}$' }
    * match inquiry.response.resultCode == '<resultCode>'
    * match inquiry.response.resultDescription == '<resultDescription>'
    * if ('<resultCode>' == 'CP0000') karate.call('classpath:financiera/bcp/inquire.feature@name=validateSuccessfulInquiry', inquiry.response)
    * if ('<resultCode>' == 'CP0006') karate.call('classpath:financiera/bcp/inquire.feature@name=validateNoDebtInquiry', inquiry.response)

    Examples:
      | caso           | dni        | resultCode | resultDescription      |
      | DNI con deuda  | 15785623   | CP0000     | PROCESO CONFORME       |
      | DNI sin deuda  | 00000000   | CP0006     | SIN DEUDA PENDIENTE    |

  @ignore @name=validateSuccessfulInquiry
  Scenario: Validar respuesta de consulta con deuda
    * match resultCode == 'CP0000'
    * match resultDescription == 'PROCESO CONFORME'
    * match customerName == '#string'
    * match operationNumberCompany == '#string'
    * match documents == '#array'
    * match documents == '#[_ > 0]'
    * match documents[0] contains { documentId: '#string', expirationDate: '#string', documentReference: '#string', amounts: '#array' }
    * match documents[0].amounts == '#[_ > 0]'
    * match documents[0].amounts[0] contains { amountType: 'totalAmount', amount: '#notnull' }

  @ignore @name=validateNoDebtInquiry
  Scenario: Validar respuesta de consulta sin deuda
    * match resultCode == 'CP0006'
    * match resultDescription == 'SIN DEUDA PENDIENTE'
    * match resultCodeCompany == 'BCP_INQUIRE_001'
    * match resultDescriptionCompany == 'Customer has no pending installments'
    * match documents == '#notpresent'
