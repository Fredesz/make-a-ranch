# Make a Ranch

MVP de un juego de rancho para Roblox, desarrollado en **Luau + Rojo**. El
jugador recibe una parcela, compra y planta semillas, cosecha cultivos con
variantes, vende productos y usa Coins para ampliar el rancho. Un Chicken Coop
produce huevos que también pueden recogerse y venderse.

Esta guía está dirigida a quien entra por primera vez al repositorio. El código
del repositorio es la fuente de verdad: Roblox Studio se usa para sincronizar,
ejecutar y comprobar el juego.

## 1. Preparar el entorno

Necesitas Roblox Studio con el plugin de Rojo, Git, Rokit y Node.js. Rokit
instala la versión de Rojo fijada en `rokit.toml` (actualmente 7.7.0). Node.js
se usa para generar el mapa y ejecutar la suite local. Para las pruebas Luau
también necesitas un ejecutable del intérprete Luau; se busca en
`.cache/luau/luau.exe` o en la ruta indicada por `LUAU_BIN`.

En PowerShell:

```powershell
git clone https://github.com/Fredesz/make-a-ranch.git
cd make-a-ranch
rokit install
rojo --version
node --version
```

Si ya tienes una copia local, entra en ella, comprueba que no haya cambios
propios pendientes con `git status` y actualiza la rama con Git antes de
trabajar. No reemplaces archivos locales sin revisar esos cambios.

## 2. Abrir y sincronizar el juego

1. Abre en Roblox Studio la experiencia de prueba publicada de **Make a Ranch**.
   Para probar DataStore desde Studio, esa experiencia debe tener habilitado
   el acceso de Studio a API Services. Usa datos de prueba, no una partida de
   producción.
2. Desde la raíz del repositorio, abre una terminal de PowerShell y ejecuta:

   ```powershell
   rojo serve default.project.json
   ```

3. Mantén esa terminal abierta. En Studio, abre el plugin de Rojo y conéctalo
   a `localhost:34872`.
4. Confirma en Explorer que aparecen las rutas de la tabla siguiente. El mapa
   debe verse también **antes** de pulsar Play; los sistemas de jugador se
   activan al iniciar Play.
5. Pulsa **Play** para verificar el inicio del servidor y del cliente. Abre
   **View → Output** y revisa los errores de scripts.

Si el puerto 34872 está ocupado, puede que ya haya otro servidor Rojo abierto.
Usa ese servidor si corresponde a este repositorio; de lo contrario ciérralo o
arranca uno distinto con `rojo serve default.project.json --port 34873` y
conecta el plugin al mismo puerto. No necesitas dos servidores para el mismo
place.

También puedes construir una copia local del place sin abrir Studio:

```powershell
rojo build default.project.json -o build/make-a-ranch.rbxlx
```

El resultado de `build/` es generado y Git lo ignora. Una construcción exitosa
comprueba el árbol de Rojo; la interacción y los DataStores requieren Play.

## 3. Dónde está cada cosa

| Ruta del repositorio | Ubicación en Studio | Responsabilidad |
| --- | --- | --- |
| `src/world/default.project.json` | `Workspace` | Mapa permanente: plaza, ocho parcelas, suelo, cercas, carteles y estaciones. |
| `src/lighting/default.project.json` | `Lighting` | Ambiente e iluminación del place. |
| `src/shared/Config/` | `ReplicatedStorage/Shared/Config` | Valores compartidos de cultivos, variantes, productos, edificios, animales, parcelas y datos. |
| `src/server/` | `ServerScriptService/Server` | Inicio del servidor, datos y reglas de juego. |
| `src/server/Services/` | `ServerScriptService/Server/Services` | Servicios de parcelas, cultivo, compras, ventas, construcciones, gallinero, guardado y HUD. |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/Client` | HUD, entradas y previsualización de construcción. |
| `tests/` | Solo repositorio | Pruebas locales con dobles mínimos de Roblox. |
| `tools/generate-map.mjs` | Solo repositorio | Generador del mapa permanente. |
| `docs/` | Solo repositorio | Pasos de prueba y decisiones de las fases. |

`default.project.json` define este mapeo. Rojo sincroniza las fuentes del
repositorio hacia Studio. `src/shared/TestModule.luau` es un módulo antiguo
de comprobación de Rojo; el gameplay no depende de él.

### Lectura rápida del código

- `src/server/init.server.luau` inicializa los servicios. Empieza aquí para
  entender el orden de arranque.
- `PlotService` asigna una de ocho parcelas y valida su dueño. El mapa de esas
  parcelas ya existe en `Workspace`; no se genera al pulsar Play.
- `PlayerDataService` conserva en servidor `Coins`, `Seeds`, `Inventory` y
  `Buildings`. Entrega copias al consultar datos y aplica cambios económicos.
- `DataService` valida, carga y guarda esos datos en el DataStore configurado
  por `DataConfig`. Los guardados antiguos sin `Seeds` reciben la cantidad
  inicial de `CropConfig.Carrot.StartingSeeds`.
- `CropService` controla plantación, crecimiento, variantes listas para cosecha
  y consumo de semillas. Por ahora admite **exactamente un cultivo**.
- `SeedShopService`, `SellService` y `BuildService` verifican en servidor
  compras, ventas y colocación. `ChickenService` produce y entrega Egg.
- `HudService` expone el estado al HUD; el cliente muestra datos y solicita
  acciones, pero no decide precios, saldo, RNG ni propiedad de parcelas.

Los `RemoteEvent` y `RemoteFunction` usados por el juego son creados por los
servicios durante el inicio. No hace falta crearlos manualmente en Studio.

## 4. Recorrido funcional para comprobar cambios

1. Entra con Play y verifica que recibes una parcela con tu nombre en el
   cartel. El máximo previsto es de ocho jugadores.
2. Ve a la estación amarilla de tu parcela y compra una Carrot Seed con su
   prompt. Comprueba Coins y Seeds en el HUD.
3. Usa el prompt del suelo marrón para plantar. Espera el tiempo configurado
   en `CropConfig` y cosecha. El producto entra en Inventory con una variante.
4. Ve a la estación azul y vende la primera pila disponible. Comprueba que
   baja Inventory y suben Coins. El puesto acepta Carrot y Egg.
5. Usa los botones del HUD para previsualizar una construcción, `R` para girar
   y clic para colocarla. También puedes usar `B` (Barn), `F` (Small Field)
   o `C` (Chicken Coop).
6. Small Field añade otra zona de cultivo. Chicken Coop muestra una gallina;
   tras el tiempo de `AnimalConfig.Chicken.ProductionTime`, recoge Egg y
   véndelo en la estación azul.
7. Detén Play y vuelve a entrar. Comprueba que Coins, semillas, inventario y
   edificios se restauraron. Los cultivos que estaban creciendo y el
   temporizador de Egg **no** se guardan todavía.

Barn es una construcción colocable sin producción propia en este MVP. El
inventario del HUD muestra un número limitado de entradas y el puesto vende
la primera pila compatible; son limitaciones conocidas, no fallos de carga.

## 5. Pruebas automáticas y diagnóstico

Desde la raíz del repositorio:

```powershell
node tests/run.mjs
rojo build default.project.json -o build/make-a-ranch.rbxlx
git diff --check
```

`tests/run.mjs` ensambla los módulos Luau reales con `tests/roblox-mock.luau`
y ejecuta casos de parcelas, cultivos, economía, edificios, huevos y DataStore.
No sustituye a Studio para comprobar controles, UI, sincronización visual o el
DataStore real. Los documentos `docs/phase*-testing.md` contienen recorridos
manuales por fase.

El intérprete Luau no está versionado. Si la primera orden falla porque falta
`.cache/luau/luau.exe`, coloca una copia local allí o indica una ruta existente
en la sesión de PowerShell:

```powershell
$env:LUAU_BIN = 'C:\ruta\a\luau.exe'
node tests/run.mjs
```

Si una prueba de DataStore falla en Studio, comprueba que estás usando un place
publicado, que Studio tiene acceso a API Services y que **Output** no informa
de un error de lectura o guardado. Cuando falla la lectura, el juego permite
una sesión provisional, pero evita sobrescribir la partida guardada.

## 6. Cambiar configuraciones y mapa

Los valores de gameplay viven en `src/shared/Config/`. Por ejemplo:

- `CropConfig`: precio de compra y venta, semillas iniciales, crecimiento y
  aspecto del cultivo.
- `VariantConfig`: pesos relativos del RNG y multiplicadores de valor.
- `ProductConfig`: precio de venta de Egg, separado del precio del animal.
- `BuildingConfig`: precios, tamaño y aspecto de construcciones.
- `AnimalConfig`: valores de Chicken y tiempo de producción.
- `PlotConfig`: medidas y distancias de interacción.
- `DataConfig`: nombre del DataStore y prefijo de clave.

Para cambiar un valor, edita la configuración correspondiente, sincroniza con
Rojo y prueba el efecto tanto en las pruebas locales como en Play. No añadas
otro cultivo solo a `CropConfig`: `CropService` comprueba que haya exactamente
uno y `SeedShopService` está preparado únicamente para Carrot. Añadir un
edificio tampoco actualiza automáticamente los botones del HUD.

El mapa permanente se genera desde `tools/generate-map.mjs`. Para cambiar
geometría o colores, modifica ese generador y después ejecuta:

```powershell
node tools/generate-map.mjs
rojo build default.project.json -o build/make-a-ranch.rbxlx
```

El generador actualiza `src/world/default.project.json`. Revisa y versiona
**ambos** archivos. Reconecta Rojo si los cambios del archivo de proyecto no
aparecen en Studio. Los cambios hechos únicamente en Studio sobre piezas
controladas por Rojo pueden perderse al volver a sincronizar.

## 7. Flujo de trabajo con Git

`main` contiene el estado compartido estable. `develop` es la rama de
integración y cada fase se trabaja en `feature/*`. Antes de editar:

```powershell
git fetch origin
git switch develop
git merge --ff-only origin/main
git switch -c feature/nombre-de-la-fase
```

Si el fast-forward falla, revisa el historial y coordina la integración; no
uses `push --force`. Una fase debe mantener un alcance claro y probarse antes
del commit. Comprueba los cambios con `git status` y `git diff`, ejecuta las
pruebas locales, haz la prueba manual en Studio y documenta el resultado. Al
cerrar la fase, realiza un commit con un mensaje descriptivo y actualiza
`main` según lo acordado con el equipo.

No subas `build/`, `.cache/` ni archivos `.rbxlx`: son resultados locales.
