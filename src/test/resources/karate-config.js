function fn() {
  var env = karate.env || 'dev';
  var localConfig = {};
  var environmentConfig = {};
  var localConfigFile = new java.io.File('src/test/resources/karate-config-local.json');

  if (localConfigFile.isFile()) {
    var localConfigJson = new java.lang.String(
      java.nio.file.Files.readAllBytes(localConfigFile.toPath()),
      java.nio.charset.StandardCharsets.UTF_8
    );
    localConfig = JSON.parse(localConfigJson);
    environmentConfig = localConfig[env] || {};
  }

  function valueOf(name) {
    return karate.properties[name] || java.lang.System.getenv(name) ||
      environmentConfig[name] || localConfig[name];
  }

  function environmentBaseUrl() {
    var environmentValue = valueOf('BCP_BASE_URL_' + env.toUpperCase());
    return environmentValue || valueOf('API_BASE_URL');
  }

  var config = {
    env: env,
    baseUrl: environmentBaseUrl(),
    bcpUsername: valueOf('PAGOS_USERNAME'),
    bcpPassword: valueOf('PAGOS_PASSWORD'),
    customerId: karate.properties['customerId'],
    operationNumber: karate.properties['operationNumber'],
    commonHeaders: { 'Content-Type': 'application/json', Accept: 'application/json' },
    debtRestorationRetry: { count: 12, interval: 5000 }
  };

  config.requireBcpConfiguration = function() {
    if (!config.baseUrl) karate.fail('API_BASE_URL o BCP_BASE_URL_<AMBIENTE> es obligatorio');
    if (!config.bcpUsername) karate.fail('PAGOS_USERNAME es obligatorio');
    if (!config.bcpPassword) karate.fail('PAGOS_PASSWORD es obligatorio');
  };

  config.requireEightDigitValue = function(name, value) {
    if (value == null || !/^\d{8}$/.test(String(value))) {
      karate.fail(name + ' es obligatorio y debe contener exactamente 8 dígitos');
    }
    return String(value);
  };

  config.nowWithoutZone = function() {
    var formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    return java.time.LocalDateTime.now().format(formatter);
  };

  config.bcpAuthorization = function() {
    var credentials = new java.lang.String(config.bcpUsername + ':' + config.bcpPassword);
    return 'Basic ' + java.util.Base64.getEncoder().encodeToString(credentials.getBytes('UTF-8'));
  };

  config.bcpEndpoint = function(endpointPath) {
    return config.baseUrl + (config.baseUrl.endsWith('/') ? '' : '/') + endpointPath;
  };

  config.waitForTransactionPersistence = function() {
    java.lang.Thread.sleep(5000);
  };

  karate.log('karate.env:', env);
  return config;
}
