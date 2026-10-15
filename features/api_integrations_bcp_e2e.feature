@bcp
Feature: E2E /integrations/bcp (inquire → payment → annulment)

  @regression @QATEST-1841
  Scenario: [EXTERNAL:BCP] Consultar la deuda, pagarla, anular el pago y verificar que la deuda vuelve
    # Evidencia para el ticket: al terminar, pase o falle, se escribe target/karate-reports/evidencia-<ticket>.html
    # (plantilla features/support/test-evidence-bcp.html). Para Jira: "Copiar imagen" y pegar en el ticket.
    * def evidenceStart = java.lang.System.currentTimeMillis()
    * configure afterScenario = read('classpath:features/support/test-evidence-bcp.js')

    * match customerId == '#regex \\d{8}'
    * def operationNumber = operationNumber || newOperationNumber()
    * print 'customerId:', customerId, 'operationNumber:', operationNumber
    * def bcpApi = 'classpath:features/support/bcp-api.feature'

    # Consultar: el cliente debe tener deuda.
    * def inquiry = call read(bcpApi + '@name=inquire') { customerId: '#(customerId)' }
    * match inquiry.response contains { rqUUID: '#uuid', resultCode: 'CP0000', resultDescription: 'PROCESO CONFORME', documents: '#[_ > 0]' }
    * def documents = inquiry.response.documents
    * match documents[0] contains { documentId: '#string', amounts: '#[_ > 0]' }

    # Pagar: con los documentos y el monto total devueltos por la consulta.
    * def payment = call read(bcpApi + '@name=payment') { customerId: '#(customerId)', operationNumber: '#(operationNumber)', amountTotal: '#(documents[0].amounts[0].amount)', documents: '#(documents)' }
    * match payment.response contains { rqUUID: '#uuid', resultCode: 'CP0000', resultDescription: 'PROCESO CONFORME' }

    # El backend aplica el pago a la cuota de forma asíncrona (~15 s). Si la anulación llega antes,
    # la cuota queda pagada sin transacción y la deuda no vuelve.
    * java.lang.Thread.sleep(paymentSettleMs)

    # Anular el pago.
    * def annulment = call read(bcpApi + '@name=annulment') { customerId: '#(customerId)', operationNumber: '#(operationNumber)' }
    * match annulment.response contains { rqUUID: '#uuid', resultCode: 'CP0000', resultDescription: 'PROCESO CONFORME' }

    # Verificar: la misma cuota vuelve a figurar como deuda (hasta 60 s, cada 5 s).
    * def restored = call read(bcpApi + '@name=inquire') { customerId: '#(customerId)', retryCondition: "response.resultCode == 'CP0000'", retryConfig: '#(debtRestorationRetry)' }
    * match restored.response.documents[0].documentId == documents[0].documentId
