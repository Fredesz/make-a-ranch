# Fase 12: HUD y flujos del MVP

El HUD utiliza botones grandes de colores vivos, contornos oscuros y una barra
superior para Coins, semillas y estado del Egg. Las referencias visuales
inspiraron la jerarquía y el estilo; no se añadieron compras con Robux,
renacimiento ni mascotas fuera del alcance del MVP.

- **TIENDA** muestra el precio de Carrot Seed y compra una unidad. El servidor
  exige estar cerca del puesto amarillo y calcula el precio desde CropConfig.
- **BOLSA** muestra todas las pilas del inventario en una lista desplazable.
  El jugador elige ItemId y Variant y vende la pila cerca del puesto azul.
  SellService valida distancia, existencia, cantidad y precio del servidor.
- **CREAR** abre Barn, Small Field y Chicken Coop; conserva la vista previa,
  rotación con `R` y validación de colocación del servidor.
- **GUÍA** explica el ciclo básico. Los avisos muestran errores legibles y
  las variantes Golden y Rainbow conservan su brillo.

Pruebas locales: `node tests/run.mjs`, `rojo build default.project.json` y
`git diff --check`. La suite incluye intentos de compra y venta por los nuevos
RemoteEvents desde lejos y comprueba que el cliente no puede elegir precio.

Prueba en Roblox Studio mediante MCP sobre el place de prueba publicado:

1. HUD y paneles cargaron sin errores de scripts; monedas y semillas aparecieron
   debajo de la barra superior de Roblox.
2. BOLSA mostró `Egg / Normal ×1` con precio estimado de 75 Coins. Seleccionar
   la pila funcionó. Vender desde lejos fue rechazado y no cambió el saldo.
3. Cerca del puesto azul, vender esa pila dejó Inventory vacío y subió Coins
   de 302 a 377.
4. TIENDA abrió correctamente. Cerca del puesto amarillo, comprar una semilla
   bajó Coins de 377 a 367 y subió Seeds de 0 a 1.
5. CREAR activó y desactivó la vista previa de Small Field. Output mostró solo
   los mensajes normales de inicio.

Para repetir la comprobación visual, abre Play, recorre los cuatro accesos,
prueba la tienda y una venta válida/inválida, gira una previsualización y revisa
Output. Comprueba también el HUD en una ventana estrecha antes de publicar.
