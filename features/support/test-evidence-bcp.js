// Hook afterScenario de la regresión BCP: se ejecuta siempre (pase o falle) y escribe la evidencia en
// target/karate-reports/evidencia-<ticket>.html, a partir de la plantilla test-evidence-bcp.html.
// Toma solo los campos necesarios de cada llamada: nunca las credenciales.
function fn() {
  try {
    var inquiry = karate.get('inquiry');
    var firstDocument = inquiry && inquiry.response && inquiry.response.documents ? inquiry.response.documents[0] : null;

    var check = function(text, ok) { return { text: text, ok: !!ok }; };
    var conforme = function(r) {
      return [check('resultCode = CP0000', r.resultCode == 'CP0000'),
              check('resultDescription = PROCESO CONFORME', r.resultDescription == 'PROCESO CONFORME')];
    };
    var steps = [
      { key: 'inquiry', name: 'Consulta de deuda',
        checks: function(r) { return conforme(r).concat([check('Tiene deuda pendiente', r.documents && r.documents.length > 0)]); } },
      { key: 'payment', name: 'Pago', checks: conforme },
      { key: 'annulment', name: 'Anulación', note: 'tras ' + (karate.get('paymentSettleMs') / 1000) + ' s de espera', checks: conforme },
      { key: 'restored', name: 'Deuda restituida',
        checks: function(r) {
          var documentId = firstDocument ? firstDocument.documentId : '';
          return [check('resultCode = CP0000', r.resultCode == 'CP0000'),
                  check('Vuelve el documento ' + documentId, r.documents && r.documents[0].documentId == documentId)];
        } }
    ];

    var headers = {};
    var commonHeaders = karate.get('commonHeaders');
    for (var h in commonHeaders) headers[h] = commonHeaders[h];
    headers['Authorization'] = 'Basic ****';

    var cards = [];
    var executed = [];
    for (var i = 0; i < steps.length; i++) {
      var call = karate.get(steps[i].key);
      executed.push(!!call);
      if (!call) continue;
      cards.push({
        name: steps[i].name,
        note: steps[i].note,
        method: 'POST',
        url: karate.get('apiUrl') + '/' + call.endpointPath,
        expectedStatus: 200,
        status: call.responseStatus,
        durationMs: call.responseTime,
        request: { headers: headers, queryParams: {}, body: call.requestBody },
        response: { body: call.response },
        assertions: steps[i].checks(call.response),
        executedAt: call.response.operationDate
      });
    }

    var ticket = karate.filter(karate.tags, function(t) { return t.indexOf('QATEST-') == 0 })[0] || 'regresion-bcp';
    var evidence = {
      ticket: ticket,
      environment: karate.get('env'),
      customerId: karate.get('customerId'),
      operationNumber: karate.get('operationNumber'),
      documentId: firstDocument ? firstDocument.documentId : null,
      amount: firstDocument ? firstDocument.amounts[0].amount : null,
      executedAt: inquiry ? inquiry.response.operationDate : new Date().toISOString(),
      durationMs: java.lang.System.currentTimeMillis() - karate.get('evidenceStart'),
      error: karate.info.errorMessage || null,
      steps: steps.map(function(s, i) { return { name: s.name, executed: executed[i] }; }),
      cards: cards
    };

    var json = JSON.stringify(evidence).split('</').join('<\\/');
    var template = karate.readAsString('classpath:features/support/test-evidence-bcp.html');
    karate.write(template.split('/*@@EVIDENCE@@*/ null').join(json), 'evidencia-' + ticket + '.html');
  } catch (e) {
    karate.log('No se pudo generar la evidencia:', e);
  }
}
