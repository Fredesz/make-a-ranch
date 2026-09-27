# Fase 7: tienda de semillas

El puesto amarillo `SeedShop` vende una semilla de Carrot por interacción.
`SeedShopService.Buy` permite comprar varias desde el servidor. El precio viene
de `CropConfig.Carrot.BuyPrice`; el servidor valida monedas, cantidad, parcela
y distancia antes de modificar el saldo y las semillas.

Pruebas locales: `node tests/run.mjs`. Cubren compra válida, cantidad inválida,
fondos insuficientes, cultivo desconocido, parcela ajena y distancia.

Prueba en Studio mediante MCP: el puesto apareció en la parcela; comprar dos
semillas aumentó el saldo de 10 a 12 y redujo las monedas de 100 a 80. La
compra sin fondos fue rechazada. Output no mostró errores y Play se detuvo.

El primer alcance de la fase incluye solo Carrot, según el orden del roadmap.
Corn y Strawberry aún no están configurados ni disponibles.
