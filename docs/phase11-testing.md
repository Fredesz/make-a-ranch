# Fase 11: persistencia

El servidor guarda `Coins`, `Seeds`, `Inventory`, `Buildings`, cultivos activos y
el momento de producción del próximo `Egg` en
`MakeARanch_MVP_v1`, con una clave por `UserId`. Al entrar, valida el valor
guardado, restaura datos y reconstruye edificios, campos y gallinero. Al salir
y al cerrar el servidor, usa `UpdateAsync` para guardar una copia.
Las semillas compradas y consumidas forman parte del saldo del jugador.
Los datos antiguos sin `Seeds` reciben `CropConfig.Carrot.StartingSeeds` una
sola vez y se guardan con el nuevo campo en la siguiente escritura.
Los guardados antiguos sin producción activa cargan sin cultivos; el gallinero
comienza un ciclo nuevo. Los tiempos se guardan como fechas absolutas: el tiempo fuera del
juego también cuenta.

Mientras la carga está pendiente, las operaciones económicas y la plantación
rechazan el uso de datos provisionales. Si falla la lectura, se permite jugar
con datos de sesión pero se evita sobrescribir la clave existente al salir.

Pruebas locales: `node tests/run.mjs`. Un DataStore simulado verificó el ciclo
salir/volver a entrar con monedas, inventario Golden y Small Field reconstruido;
el campo restaurado volvió a aceptar una siembra. También verificó que dos
semillas compradas persisten, que una semilla plantada se descuenta tras otra
reconexión y que un guardado antiguo sin `Seeds` sigue cargando.
La suite también comprueba cultivos en la parcela principal y Small Field,
variantes estables, un huevo en espera, producción mientras el jugador está
fuera y ausencia de recompensas duplicadas.

Prueba real en Studio: se publicó `Make a Ranch Test` (GameId `10768393135`,
PlaceId `108786797233253`) y se activó el acceso de Studio a API Services.
Se guardaron 137 monedas y dos `Carrot` de variante `Normal`, se compró un
`SmallField` por 50 monedas y un `ChickenCoop` por 70. Tras detener Play y
volver a entrar, el DataStore contenía 17 monedas, el inventario con las dos
zanahorias y ambos edificios. Los dos se reconstruyeron en la parcela. La
consola del último inicio mostró solamente los mensajes normales de arranque.

El jugador confirmó en Roblox Studio que la persistencia de semillas funciona.
Pasos para repetir la prueba manual:

1. Inicia Play en la experiencia de prueba publicada y anota Coins y Seeds.
2. Compra dos semillas en Seed Shop; verifica que Coins baje 20 y Seeds suba 2.
3. Detén Play y vuelve a entrar; verifica que ambos saldos sigan iguales.
4. Planta una Carrot; verifica que Seeds baje 1.
5. Detén Play y vuelve a entrar; verifica que Seeds conserve el nuevo valor.
6. Revisa Output para confirmar que no haya errores de carga o guardado.

Prueba en Studio mediante MCP en `Make a Ranch Test`: se plantó Carrot, se
confirmó que el DataStore guardó `ActiveCrops` y `EggReadyAt`, y tras detener
Play y volver a entrar el cultivo reapareció listo con la misma variante
`Normal`; el huevo también estaba disponible. Output mostró solo los mensajes
normales de inicio.

Pasos para repetir la prueba de producción activa:

1. Planta una Carrot y coloca un Chicken Coop; anota el estado antes de 30 s.
2. Detén Play y vuelve a entrar. El cultivo debe conservar su progreso y el
   huevo debe aparecer al cumplirse el tiempo de producción, incluso si pasó
   mientras estabas fuera.
3. Cosecha y recoge una sola vez. Confirma que inventario no se duplica.
4. Repite con una Carrot plantada en Small Field y revisa Output.

Esta experiencia es exclusivamente para pruebas de persistencia. Si se cambia
el esquema de datos en fases posteriores, usar otra clave o migrar los datos
antes de reutilizarla.
