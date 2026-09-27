# Fase 8: construcción

Pulsa B en Play para mostrar la vista previa de Barn. Mueve el cursor sobre tu
parcela; verde indica una posición libre y roja una posición inválida. Pulsa R
para girar 90 grados y clic izquierdo para solicitar la colocación. El cliente
solo sugiere una posición; `BuildService` vuelve a validar todo en el servidor.

El precio, tamaño y color están en `BuildingConfig`; el grid y la parcela en
`PlotConfig`. El Barn cuesta 80 monedas en este MVP.

Pruebas locales: `node tests/run.mjs`. Incluyen límites, suelo de cultivo,
puestos de venta y semillas, superposición, giro, saldo, dueño y copias de datos.

Prueba en Studio mediante MCP: servidor rechazó centro ocupado, fuera de la
parcela, giro inválido, superposición y falta de dinero. Colocó Barn rotado,
guardó su posición y redujo monedas de 100 a 20. Cliente mostró vista previa
al pulsar B; el giro con R no produjo errores. Output sin errores. Play detenido.
