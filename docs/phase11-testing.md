# Fase 11: persistencia

El servidor guarda `Coins`, `Seeds`, `Inventory` y `Buildings` en
`MakeARanch_MVP_v1`, con una clave por `UserId`. Al entrar, valida el valor
guardado, restaura datos y reconstruye edificios, campos y gallinero. Al salir
y al cerrar el servidor, usa `UpdateAsync` para guardar una copia.
Las semillas compradas y consumidas forman parte del saldo del jugador.
Los datos antiguos sin `Seeds` reciben `CropConfig.Carrot.StartingSeeds` una
sola vez y se guardan con el nuevo campo en la siguiente escritura.

Mientras la carga está pendiente, las operaciones económicas y la plantación
rechazan el uso de datos provisionales. Si falla la lectura, se permite jugar
con datos de sesión pero se evita sobrescribir la clave existente al salir.

Pruebas locales: `node tests/run.mjs`. Un DataStore simulado verificó el ciclo
salir/volver a entrar con monedas, inventario Golden y Small Field reconstruido;
el campo restaurado volvió a aceptar una siembra. También verificó que dos
semillas compradas persisten, que una semilla plantada se descuenta tras otra
reconexión y que un guardado antiguo sin `Seeds` sigue cargando.

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

Los cultivos plantados y el temporizador de Egg siguen siendo estados de
sesión; su persistencia queda fuera de este cambio.

Esta experiencia es exclusivamente para pruebas de persistencia. Si se cambia
el esquema de datos en fases posteriores, usar otra clave o migrar los datos
antes de reutilizarla.
