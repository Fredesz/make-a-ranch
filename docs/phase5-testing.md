# Fase 5: prueba de inventario en Roblox Studio

## Estado

Las pruebas locales ejecutan el código real de los servicios con APIs de Roblox
simuladas. Pasan diez cosechas, separación de variantes, acumulación de unidades,
rechazo de productos inválidos y conservación del cultivo cuando el inventario
rechaza una adición. Luau compila y Rojo genera el proyecto. Queda pendiente
confirmar el flujo real en Studio antes del commit `feat: add basic inventory`.

## Prueba manual

1. Detén Play, sincroniza la rama `feature/inventory` con Rojo y verifica que
   `ServerScriptService.Server.Services.InventoryService` aparezca en Explorer.
2. Inicia Play. Usa Plant en tu espacio y espera hasta que el cultivo esté Ready.
   Comprueba `CropSlot.Variant` en Explorer del servidor antes de cosechar.
3. Cosecha con E. El cultivo debe desaparecer y el espacio quedar Empty.
4. En la **Command Bar en modo Server**, ejecuta:

   ```luau
   local server = game.ServerScriptService.Server
   local inventory = require(server.Services.InventoryService)
   local data = require(server.PlayerDataService)
   local player = game.Players:GetPlayers()[1]
   local entries = inventory.GetInventory(player)
   assert(#entries == 1 and entries[1].ItemId == "Carrot")
   assert(entries[1].Quantity == 1)
   assert(data.GetCoins(player) == 100)
   for _, entry in entries do
       print(entry.ItemId, entry.Variant, entry.Quantity)
   end
   print("PASS: primera cosecha en inventario")
   ```

5. Planta y cosecha más Carrots. Ejecuta de nuevo este bloque en Server:

   ```luau
   local inventory = require(game.ServerScriptService.Server.Services.InventoryService)
   local player = game.Players:GetPlayers()[1]
   local total = 0
   local seen = {}
   for _, entry in inventory.GetInventory(player) do
       assert(entry.ItemId == "Carrot")
       assert(entry.Quantity >= 1)
       assert(not seen[entry.Variant], "Variante duplicada en dos entradas")
       seen[entry.Variant] = true
       total += entry.Quantity
       print(entry.ItemId, entry.Variant, entry.Quantity)
   end
   print("Total cosechado:", total)
   ```

   `total` debe coincidir con la cantidad de cosechas de esa sesión. Variantes
   distintas deben aparecer como entradas distintas; cosechas de la misma
   variante deben aumentar `Quantity` de su entrada.
6. Repite con Normal, Golden y Rainbow. Para forzar cada variante, usa los pesos
   de prueba descritos en `docs/phase4-testing.md`, reinicia Play entre cambios
   y restaura `94/5/1` al terminar.
7. Revisa Output: no deben aparecer errores rojos. Al salir y volver a entrar,
   el inventario estará vacío porque aún no hay DataStore.

No hay HUD de inventario en esta fase. La inspección se hace en la Command Bar
del servidor. Tampoco hay venta ni monedas por cosecha.

## Resultado en Studio — 2026-09-27

Prueba ejecutada mediante las herramientas Roblox_Studio en Place1.

- Siembra y cosecha reales con E, crecimiento original de 30 segundos: PASS.
- Primera Carrot Normal añadida al inventario; cultivo eliminado y slot Empty: PASS.
- Diez cosechas totales: Normal 4, Golden 3, Rainbow 3; acumulación sin entradas duplicadas: PASS.
- Las nueve cosechas adicionales usaron GrowthTime 0.3 y VariantRng.Roll controlado en memoria durante Play. Se verificaron atributo Variant y color de cada cultivo; no fue una prueba estadística del RNG ni una revisión visual por captura.
- Cosecha prematura, productos/variantes desconocidos y cantidades inválidas rechazados: PASS.
- Fallo simulado de AddCrop conserva el cultivo Ready; reintento correcto: PASS.
- Copias de inventario no permiten modificar los datos internos; semillas agotadas impiden plantar: PASS.
- Monedas conservadas en 100: PASS.
- Nueva sesión: inventario vacío, 100 monedas, crecimiento 30 y pesos 94/5/1: PASS.

La lectura directa con require desde execute_luau no compartió el estado de los módulos del juego; una consulta inicial produjo un error de la sonda (slot nil). Las comprobaciones se ejecutaron después mediante Scripts temporales del servidor durante Play. No se observaron errores del juego; la sesión nueva mostró únicamente los mensajes de inicio y PASS.

Studio quedó en Edit. Las sondas y ajustes temporales desaparecieron al detener Play. No se modificaron scripts del juego ni se realizó commit.
