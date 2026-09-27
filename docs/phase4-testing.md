# Fase 4: variantes de cultivos en Roblox Studio

## Estado

Las pruebas locales de sorteos controlados, diez ciclos de cultivo, compilación
Luau y build de Rojo pasan. Queda pendiente comprobar la sincronización y el
resultado visual en Studio antes del commit `feat: add crop rng variants`.

## Prueba visual

1. Detén Play. Sincroniza `feature/crop-variants` con el plugin Rojo.
2. Comprueba que `ServerScriptService.Server.Services` tenga `VariantRng` y
   `CropService`, y que `ReplicatedStorage.Shared.Config.VariantConfig`
   contenga Normal, Golden y Rainbow.
3. Para ver las tres variantes sin esperar resultados raros, cambia
   temporalmente los `Weight` en `VariantConfig`:
   - Solo Normal: Normal 1, Golden 0, Rainbow 0.
   - Solo Golden: Normal 0, Golden 1, Rainbow 0.
   - Solo Rainbow: Normal 0, Golden 0, Rainbow 1.
4. En cada prueba, deja una variante con peso 1 y las otras con peso 0.
   Reinicia Play tras cambiar los pesos; el servidor lee la configuración al
   iniciar. Debe quedar al menos un peso mayor que cero.
5. Inicia Play y planta una Carrot. Al terminar el crecimiento, su color debe
   reflejar la variante: naranja (Normal), amarillo (Golden), morado (Rainbow).
6. En Explorer del **servidor**, `CropSlot.Variant` debe ser el identificador
   correspondiente. Al cosechar debe desaparecer junto con el cultivo.
7. Restaura los pesos originales `94`, `5`, `1` y reinicia Play al terminar.

El sorteo ocurre una sola vez, al alcanzar Ready. El cliente no envía ni
selecciona la variante. La cosecha devuelve el identificador para la futura
integración con inventario, pero todavía no crea objetos ni entrega monedas.

## Comprobación desde Command Bar del servidor

Sitúate cerca de tu espacio vacío y ejecuta:

```luau
local services = game.ServerScriptService.Server.Services
local crops = require(services.CropService)
local plots = require(services.PlotService)
local player = game.Players:GetPlayers()[1]
local slot = plots.GetSlot(player)
assert(crops.Plant(player, slot))
task.wait(require(game.ReplicatedStorage.Shared.Config.CropConfig).Carrot.GrowthTime + 0.2)
local visible = slot:GetAttribute("Variant")
assert(visible == "Normal" or visible == "Golden" or visible == "Rainbow")
local ok, cropId, harvestedVariant = crops.Harvest(player, slot)
assert(ok and cropId == "Carrot" and harvestedVariant == visible)
assert(slot:GetAttribute("Variant") == nil)
print("PASS: variante conservada hasta la cosecha:", harvestedVariant)
```

Mantente cerca del espacio durante la ejecución. Repite en sesiones nuevas tras
cambiar los pesos. No modifiques `CropService` para las pruebas.
