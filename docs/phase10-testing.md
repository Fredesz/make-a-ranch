# Fase 10: Chicken Coop

Pulsa C en Play para previsualizar Chicken Coop. Cuesta 70 monedas y se permite
uno por jugador. Al colocarlo aparece una gallina. Tras el tiempo definido en
`AnimalConfig.Chicken.ProductionTime`, aparece un huevo con prompt de recolección.
El servidor valida dueño, distancia y disponibilidad. Cada huevo recogido entra
al inventario como `Egg / Normal` y se programa el siguiente.

Pruebas locales: `node tests/run.mjs`, incluida producción repetida, doble
recolección, propietario ajeno y limpieza al salir.

Prueba en Studio mediante MCP: coop colocado por 70, gallina presente, huevo
producido y recogido una vez, inventario `Egg / Normal ×1`, monedas 30. Output
sin errores y Play detenido.
