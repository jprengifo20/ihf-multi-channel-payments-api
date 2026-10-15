function fn() {
  var env = karate.env || 'dev';

  // Credenciales locales opcionales (ignoradas por git), con una sección por ambiente.
  var localConfig = {};
  try {
    localConfig = karate.read('classpath:karate-config-local.json') || {};
  } catch (e) {
    karate.log('karate-config-local.json no encontrado; se usan propiedades y variables de entorno');
  }
  var environmentConfig = localConfig[env] || {};

  // Orden de búsqueda: -D, variable de entorno, sección del ambiente en el archivo local.
  function valueOf(name) {
    return karate.properties[name] || java.lang.System.getenv(name) || environmentConfig[name];
  }

  var baseUrl = valueOf('API_BASE_URL');
  var username = valueOf('PAGOS_USERNAME');
  var password = valueOf('PAGOS_PASSWORD');
  if (!baseUrl || !username || !password) {
    karate.fail('Faltan API_BASE_URL, PAGOS_USERNAME o PAGOS_PASSWORD para el ambiente ' + env);
  }
  var credentials = new java.lang.String(username + ':' + password);

  karate.log('karate.env:', env);
  return {
    env: env,
    customerId: valueOf('customerId'),
    operationNumber: valueOf('operationNumber'),
    apiUrl: baseUrl.replace(/\/+$/, ''),
    apiAuthorization: 'Basic ' + java.util.Base64.getEncoder().encodeToString(credentials.getBytes('UTF-8')),
    commonHeaders: { 'Content-Type': 'application/json', Accept: 'application/json' },
    paymentSettleMs: Number(valueOf('paymentSettleMs') || 20000),
    debtRestorationRetry: { count: 12, interval: 5000 },

    nowWithoutZone: function() {
      var formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
      return java.time.LocalDateTime.now().format(formatter);
    },

    // 8 dígitos a partir de los segundos desde 1970: no se repite durante ~3 años.
    newOperationNumber: function() {
      var seconds = Math.floor(java.lang.System.currentTimeMillis() / 1000);
      return String(100000000 + seconds % 100000000).substring(1);
    }
  };
}
