@ignore
Feature: API del canal de pago BCP

  # Una operación por endpoint. Cada una deja `requestBody` y `response` para quien la llama:
  # call read('classpath:features/support/bcp-api.feature@name=<operación>') { ... }
  # Los cuerpos de los requests están en features/context/bcp/.

  # POST autenticado. Se llama en scope compartido: usa `endpointPath` y `requestBody` de quien llama
  # y, opcionalmente, `retryCondition` (expresión) y `retryConfig` para reintentar.
  @name=post
  Scenario: Enviar POST autenticado
    * configure retry = karate.get('retryConfig') || { count: 1, interval: 0 }
    Given url apiUrl + '/' + endpointPath
    And headers commonHeaders
    And header Authorization = apiAuthorization
    And request requestBody
    And retry until karate.eval(karate.get('retryCondition') || 'true')
    When method post
    Then status 200

  @name=inquire
  Scenario: POST /integrations/bcp/inquire
    * def endpointPath = 'integrations/bcp/inquire'
    * def requestBody = read('classpath:features/context/bcp/inquire.json')
    * call read('@name=post')

  @name=payment
  Scenario: POST /integrations/bcp/payment
    * def endpointPath = 'integrations/bcp/payment'
    * def requestBody = read('classpath:features/context/bcp/payment.json')
    * call read('@name=post')

  @name=annulment
  Scenario: POST /integrations/bcp/annulment
    * def endpointPath = 'integrations/bcp/annulment'
    * def requestBody = read('classpath:features/context/bcp/annulment.json')
    * call read('@name=post')
