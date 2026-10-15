# ihf-multi-channel-payments-api — instrucciones para agentes IA

La estructura, los comandos, los tags y el comportamiento del backend están en el [README](README.md). Léelo antes de cambiar algo.

Esto es **Karate** (Java 21 + Maven), no Cucumber ni TypeScript como los repos `-qa`: no hay step definitions, los pasos son instrucciones de Karate (`def`, `call`, `match`, `retry until`).

## Reglas

- La regresión **paga y anula de verdad** contra la API. No la ejecutes salvo que el usuario lo pida. Para validar cambios usa `mvn clean test -Dkarate.env=test -DdryRun=true`.
- No ejecutes la regresión desde las 23:00: el pago no se podría anular y el cliente dejaría de servir.
- Nunca leas, muestres ni subas `src/test/resources/karate-config-local.json`: tiene credenciales.
- No acortes ni quites la espera `paymentSettleMs` entre el pago y la anulación: sin ella la deuda no vuelve.
- No inventes llaves de Xray (`@QATEST-XXX`): agrégalas solo cuando el usuario dé el ticket.
- Mantén un solo runner (`PaymentsTest`). Un segundo runner duplicaría pagos reales en `mvn test`.
