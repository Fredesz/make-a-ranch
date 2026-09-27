# Fase 6: venta

El puesto azul `SellPad` aparece en la parcela del jugador. Su prompt vende
la primera entrada del inventario, completa. `SellService.Sell` permite probar
una cantidad y variante concretas desde el servidor. El valor se obtiene de
`CropConfig.SellPrice × VariantConfig.ValueMultiplier`.

Pruebas locales: `node tests/run.mjs`. Cubren venta válida, parcial, múltiple,
variante, objeto inexistente, saldo, distancia y parcela ajena.

Prueba realizada en Studio mediante el MCP: sincronización de `SellService`,
cosecha real de Carrot, venta de una unidad Normal, inventario vacío y saldo
de 100 a 115. Output sin errores de script. Play fue detenido al terminar.

Para revisar manualmente, entra en Play, cosecha una Carrot, acércate al puesto
azul y pulsa E. En Command Bar del servidor puedes consultar:

```luau
local server = game.ServerScriptService.Server
local player = game.Players:GetPlayers()[1]
print(require(server.PlayerDataService).GetCoins(player))
print(require(server.Services.InventoryService).GetInventory(player))
```
