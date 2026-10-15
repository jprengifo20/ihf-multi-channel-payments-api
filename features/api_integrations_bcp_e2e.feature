@bcp
Feature: E2E /integrations/bcp (inquire → payment → annulment)

  @regression @QATEST-1841
  Scenario: [EXTERNAL:BCP] Consultar la deuda, pagarla, anular el pago y verificar que la deuda vuelve
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

    # Evidencia para el ticket  "evidenceData" (solo se genera si la prueba pasó): target/karate-reports/evidencia-<ticket>.html,
    # a partir de la plantilla features/support/test-evidence-bcp.html.
    # Para adjuntarla a Jira: abrirla en el navegador, Ctrl + P → Guardar como PDF.
    * def ticket = karate.filter(karate.tags, function(t) { return t.indexOf('QATEST-') == 0 })[0]
    * def evidenceData =
      """
      {
        "ticket": "#(ticket)",
        "env": "#(env)",
        "date": "#(payment.response.operationDate.substring(0, 10).split('-').reverse().join('/'))",
        "customerId": "#(customerId)",
        "operationNumber": "#(operationNumber)",
        "documentId": "#(documents[0].documentId)",
        "amount": "#('S/ ' + documents[0].amounts[0].amount)",
        "inquiryCode": "#(inquiry.response.resultCode)",
        "inquiryDescription": "#(inquiry.response.resultDescription)",
        "inquiryTime": "#(inquiry.response.operationDate.substring(11))",
        "paymentCode": "#(payment.response.resultCode)",
        "paymentDescription": "#(payment.response.resultDescription)",
        "paymentTime": "#(payment.response.operationDate.substring(11))",
        "annulmentCode": "#(annulment.response.resultCode)",
        "annulmentDescription": "#(annulment.response.resultDescription)",
        "annulmentTime": "#(annulment.response.operationDate.substring(11))",
        "restoredCode": "#(restored.response.resultCode)",
        "restoredTime": "#(restored.response.operationDate.substring(11))"
      }
      """
    * def render = function(template, data) { for (var key in data) template = template.split('{{' + key + '}}').join(data[key]); return template }
    * karate.write(render(karate.readAsString('classpath:features/support/test-evidence-bcp.html'), evidenceData), 'evidencia-' + ticket + '.html')
    # #############################################################################################################################################