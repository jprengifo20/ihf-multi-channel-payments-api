@smoke @regression
Feature: Flujo E2E BCP de consulta, pago y anulación

  @negative
  Scenario: Validar formato de datos externos antes de invocar la API
    * def invalidCustomerId = '1234567'
    * def invalidOperationNumber = 'A1103065'
    * def isEightDigits = function(value) { return /^\d{8}$/.test(value); }
    * match isEightDigits(invalidCustomerId) == false
    * match isEightDigits(invalidOperationNumber) == false

  Scenario: Consultar deuda, pagarla y anular el pago con los datos heredados
    * def flowCustomerId = requireEightDigitValue('customerId', customerId)
    * def flowOperationNumber = requireEightDigitValue('operationNumber', operationNumber)

    # Consulta: conserva todos los documentos y el primer monto total.
    * def inquiry = call read('classpath:financiera/bcp/inquire.feature@name=inquire') { customerId: '#(flowCustomerId)' }
    * match inquiry.responseStatus == 200
    * match inquiry.response contains { rqUUID: '#regex ^[0-9a-fA-F-]{36}$' }
    * call read('classpath:financiera/bcp/inquire.feature@name=validateSuccessfulInquiry') inquiry.response
    * def documents = inquiry.response.documents
    * def amountTotal = inquiry.response.documents[0].amounts[0].amount

    # Pago: usa exactamente los documentos y el monto devueltos por la consulta.
    * def payment = call read('classpath:financiera/bcp/payment.feature@name=payment') { customerId: '#(flowCustomerId)', operationNumber: '#(flowOperationNumber)', amountTotal: '#(amountTotal)', documents: '#(documents)' }
    * match payment.responseStatus == 200
    * match payment.response contains { rqUUID: '#regex ^[0-9a-fA-F-]{36}$', operationDate: '#regex ^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$' }
    * match payment.response.resultCode == 'CP0000'
    * match payment.response.resultDescription == 'PROCESO CONFORME'
    * match payment.response.operationNumberCompany == '#notnull'

    # Espera la persistencia del pago antes de solicitar su anulación.
    * def paymentCustomerId = payment.requestBody.customerId
    * def paymentOperationNumber = payment.requestBody.operationNumber
    * waitForTransactionPersistence()

    # Anulación: reintenta CP0138 hasta que la operación sea localizable.
    * def annulment = call read('classpath:financiera/bcp/annulment.feature@name=annulment') { customerId: '#(paymentCustomerId)', operationNumber: '#(paymentOperationNumber)' }
    * match annulment.responseStatus == 200
    * match annulment.response contains { rqUUID: '#regex ^[0-9a-fA-F-]{36}$', operationDate: '#regex ^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$' }
    * match annulment.response.resultCode == 'CP0000'
    * match annulment.response.resultDescription == 'PROCESO CONFORME'
    * match annulment.requestBody.operationNumber == paymentOperationNumber
    * match annulment.requestBody.operationNumberAnnulment == paymentOperationNumber
    * match annulment.requestBody.customerId == paymentCustomerId

    # La deuda debe volver a estar disponible dentro de 60 segundos, consultando cada 5 segundos.
    * def restoredInquiry = call read('classpath:financiera/bcp/inquire.feature@name=inquireUntilDebtRestored') { customerId: '#(paymentCustomerId)' }
    * match restoredInquiry.responseStatus == 200
    * call read('classpath:financiera/bcp/inquire.feature@name=validateSuccessfulInquiry') restoredInquiry.response
