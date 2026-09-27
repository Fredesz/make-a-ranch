# Fase 3: prueba en Roblox Studio

## Estado

Implementación en `feature/crop-system`. La compilación de bytecode Luau,
el build de Rojo y las pruebas con APIs simuladas pasan. La sincronización
del plugin, el aspecto visual y las interacciones reales requieren Studio.
El commit `feat: add basic crop lifecycle` queda pendiente de esa validación.

## Preparación

1. Detén Play antes de sincronizar.
2. Desde la raíz del repositorio ejecuta `rojo serve default.project.json`.
   Si el lanzador falla, en PowerShell utiliza:

   ```powershell
   & "$env:USERPROFILE\.rokit\tool-storage\rojo-rbx\rojo\7.7.0\rojo.exe" serve default.project.json
   ```

3. Conecta el plugin Rojo a `localhost:34872`. Si ya hay un servidor de Rojo,
   usa ese servidor y comprueba que el proyecto conectado sea Make a Ranch.
4. Verifica `ServerScriptService.Server.Services`: debe contener
   `PlotService` y `CropService`. `PlayerDataService` conserva su ruta anterior
   directamente bajo `Server` para mantener compatibilidad con la Fase 2.
5. Abre Output y Script Analysis. Inicia Play.

## Parcela y diez cosechas

1. Busca `Workspace.RanchPlots.Plot_<tu UserId>` en Explorer del servidor.
   Debe contener `Ground` y `CropSlot`, con atributo `OwnerUserId` correcto.
   Las parcelas se generan alrededor de `(0, 0, 24)` y se separan sobre el eje X.
2. Acércate al cuadrado marrón y usa la acción `Plant` del ProximityPrompt
   (tecla E en PC). Comienzas con diez semillas de sesión.
3. Aparece un bloque pequeño verde. Es una representación provisional del cultivo.
   `CropSlot` muestra `CropState = Growing`, `CropId = Carrot`,
   `GrowthStage = 1` y `SeedsRemaining = 9`.
4. A los 10 segundos cambia a etapa 2; a los 20, etapa 3.
   A los 30 segundos se vuelve naranja y aparece la acción `Harvest`.
5. Cosecha. El bloque desaparece, `CropState` vuelve a `Empty` y puedes plantar.
6. Repite hasta completar diez cosechas. No deben aparecer cultivos duplicados
   ni errores rojos. Al agotar las semillas, Plant queda deshabilitado.
7. Las monedas permanecen en 100. Todavía no hay recompensas, RNG ni inventario.

Para acelerar la prueba, detén Play, cambia temporalmente
`CropConfig.Carrot.GrowthTime` de 30 a 3 y sincroniza. Las etapas durarán un
segundo cada una. Restaura 30 al terminar. No cambies el servicio para probar.

## Validaciones desde Command Bar del servidor

Inicia una sesión nueva y acércate a tu espacio. Ejecuta este bloque una sola
vez para comprobar las validaciones del servidor (espera 30 segundos):

```luau
local Players = game:GetService("Players")
local services = game.ServerScriptService.Server.Services
local crops = require(services.CropService)
local plots = require(services.PlotService)
local config = require(game.ReplicatedStorage.Shared.Config.CropConfig)
local player = Players:GetPlayers()[1]
local slot = plots.GetSlot(player)
assert(crops.Plant(player, slot))
assert(not crops.Plant(player, slot), "Permitió plantar dos veces")
assert(not crops.Harvest(player, slot), "Permitió cosechar antes de tiempo")
task.wait(config.Carrot.GrowthTime + 0.2)
assert(crops.Harvest(player, slot))
assert(not crops.Harvest(player, slot), "Permitió cosechar dos veces")
print("PASS: validaciones reales de cultivo")
```

Permanece cerca del espacio hasta que finalice el bloque.

## Dos jugadores y limpieza

1. Usa la prueba de Studio con un servidor y dos clientes.
2. Confirma que cada jugador tenga una parcela distinta.
3. Intenta usar Plant o Harvest en el espacio del otro jugador: no debe cambiar
   el cultivo ni consumir semillas. La indicación puede verse, pero el servidor
   rechaza la acción ajena.
4. Planta y desconecta ese cliente mientras crece. Su parcela debe desaparecer
   sin errores, incluso cuando transcurra el tiempo de crecimiento pendiente.
5. Reinicia la sesión: cada jugador debe recuperar 100 monedas y diez semillas.

## Pruebas locales

`node tests/run.mjs` ejecuta las fuentes reales de los módulos en Luau con
servicios de Roblox simulados y un reloj controlado. Comprueba diez ciclos,
etapas, semillas, propiedad, distancia, personaje muerto, cosecha anticipada,
doble cosecha, callbacks pendientes y regresiones de monedas/parcelas.

El ejecutable se busca en `.cache/luau/luau.exe`, descargado de las releases
oficiales de `luau-lang/luau`. Puede usarse otra instalación mediante `LUAU_BIN`.
La caché está ignorada por Git. Estas pruebas no sustituyen Studio ni su análisis
de tipos con las APIs de Roblox.
