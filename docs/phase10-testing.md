# Fase 10: Chicken Coop

Pulsa C en Play para previsualizar Chicken Coop. Cuesta 70 monedas y se permite
uno por jugador. Al colocarlo aparece una gallina. Tras el tiempo definido en
`AnimalConfig.Chicken.ProductionTime`, aparece un huevo con prompt de recolección.
El servidor valida dueño, distancia y disponibilidad. Cada huevo recogido entra
al inventario como `Egg / Normal` y se programa el siguiente.

El puesto de venta acepta Egg además de Carrot. El precio del huevo está en
`ProductConfig.Egg.SellPrice` (75 Coins). El prompt vende la primera pila
compatible del inventario; si hay Carrot primero, véndelo hasta llegar a Egg.

Pruebas locales: `node tests/run.mjs`, incluida producción repetida, doble
recolección, propietario ajeno, venta de Egg, cantidades inválidas, precio
configurado, prompt y limpieza al salir.

Prueba en Studio mediante MCP: coop colocado por 70, gallina presente, huevo
producido y recogido una vez, inventario `Egg / Normal ×1`, monedas 30. Output
sin errores y Play detenido.

Prueba manual de venta de Egg confirmada por el jugador en Roblox Studio: los
huevos recogidos se venden, Coins aumenta y el saldo persiste entre sesiones.
Pasos para repetirla:

1. Inicia Play y compra Chicken Coop por 70 Coins.
2. Colócalo y verifica que aparezca Chicken.
3. Espera 20 segundos, recoge Egg y verifica `Egg / Normal ×1` en Inventory.
4. Ve al puesto azul de venta de tu parcela y activa el prompt.
5. Verifica que Egg desaparezca del inventario y Coins suba de 30 a 105.
6. Repite el prompt sin nuevos productos y verifica que Coins siga en 105.
7. Revisa Output y confirma que no aparezcan errores de scripts.
