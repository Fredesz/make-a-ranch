# Fase 12: UI y acabado del MVP

El HUD muestra monedas, semillas e inventario consultando al servidor. Los
botones activan la vista previa de los tres edificios; `R` rota la vista y un
clic solicita la colocación al servidor. La guía recorre los pasos básicos.
Las acciones de las estaciones muestran mensajes de éxito o error, los botones
reproducen un sonido cargado por Studio y las variantes Golden y Rainbow
tienen un contorno visual. El HUD reduce su escala en pantallas estrechas.

Validación local: compilar todos los archivos Luau, `rojo build` y
`node tests/run.mjs`.

Validación en Roblox Studio con la experiencia de prueba publicada:

- El HUD cargó el estado persistido (`17` monedas, dos Carrot y ambos edificios).
- El botón Small Field activó la vista previa; una colocación fuera de la
  parcela mostró un error legible sin gastar monedas.
- Una compra de semilla actualizó monedas de `17` a `7` y semillas de `10` a
  `11`. Plantar bajó las semillas a `10`; tras 30 segundos, cosechar agregó
  una Carrot al inventario.
- Se recogió un Egg. Vender tres Carrot actualizó monedas de `7` a `52` y dejó
  el Egg en inventario.
- Tras detener Play y volver a entrar, el HUD mostró `52` monedas, un Egg y
  tanto Small Field como Chicken Coop reconstruidos.
- El contorno Golden y Rainbow se comprobó en cliente con un cultivo temporal.
  La consola final solo mostró los mensajes normales de inicio.

La experiencia de prueba usa DataStore real. Las semillas son de sesión por
diseño del MVP; por eso vuelven a su cantidad inicial en cada entrada.
