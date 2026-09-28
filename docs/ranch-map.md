# Mapa inicial del rancho

Ocho parcelas de 54 × 72 studs, en dos filas de cuatro. Cada parcela tiene una
entrada hacia el camino central, cercas y un cartel de madera visible por ambos
lados. Las montañas y la plaza también existen en modo edición.

El servidor reserva la primera parcela libre al entrar. El cartel muestra su
número, el nombre visible y el @usuario. Al salir, se restaura la parcela vacía;
los edificios guardados se cargan en la parcela que se asigne en la próxima sesión.
El personaje aparece y reaparece en la plaza central.

Configurar el máximo de jugadores del place en **8** en Creator Dashboard/Studio.
Como protección adicional, si las ocho parcelas están ocupadas, el servidor
rechaza una entrada adicional con un mensaje; nunca comparte una parcela.

## Editar el mapa

La fuente de las medidas, posiciones y colores es `tools/generate-map.mjs`.
Después de modificarla, ejecutar:

```powershell
node tools/generate-map.mjs
rojo build -o build/neighborhood.rbxlx
rojo serve
```

El generador actualiza `src/world/default.project.json`, que se incluye en el
proyecto principal. Reiniciar Rojo después de regenerar el mapa, porque los
cambios en archivos de proyecto pueden requerir reconexión. Los cambios manuales
en Studio sobre estas piezas deben trasladarse al generador para conservarlos.

## Verificación

`node tests/run.mjs` comprueba asignación exclusiva, carteles, ocho plazas,
rechazo de una novena entrada, liberación/reutilización y los sistemas de gameplay.
En Studio: probar entrada y reaparición en la plaza, leer ambos lados del cartel,
caminar por las entradas, y verificar que al detener Play vuelven los ocho
carteles a Disponible. Para la comprobación visual multijugador, iniciar dos
clientes desde Test y verificar que reciben parcelas distintas.
