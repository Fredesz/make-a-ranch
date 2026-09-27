# Fase 11: persistencia

El servidor guarda `Coins`, `Inventory` y `Buildings` en
`MakeARanch_MVP_v1`, con una clave por `UserId`. Al entrar, valida el valor
guardado, restaura datos y reconstruye edificios, campos y gallinero. Al salir
y al cerrar el servidor, usa `UpdateAsync` para guardar una copia.

Mientras la carga está pendiente, las operaciones económicas y la plantación
rechazan el uso de datos provisionales. Si falla la lectura, se permite jugar
con datos de sesión pero se evita sobrescribir la clave existente al salir.

Pruebas locales: `node tests/run.mjs`. Un DataStore simulado verificó el ciclo
salir/volver a entrar con monedas, inventario Golden y Small Field reconstruido;
el campo restaurado volvió a aceptar una siembra. Luau y Rojo compilan.

Prueba real en Studio: se publicó `Make a Ranch Test` (GameId `10768393135`,
PlaceId `108786797233253`) y se activó el acceso de Studio a API Services.
Se guardaron 137 monedas y dos `Carrot` de variante `Normal`, se compró un
`SmallField` por 50 monedas y un `ChickenCoop` por 70. Tras detener Play y
volver a entrar, el DataStore contenía 17 monedas, el inventario con las dos
zanahorias y ambos edificios. Los dos se reconstruyeron en la parcela. La
consola del último inicio mostró solamente los mensajes normales de arranque.

Esta experiencia es exclusivamente para pruebas de persistencia. Si se cambia
el esquema de datos en fases posteriores, usar otra clave o migrar los datos
antes de reutilizarla.
