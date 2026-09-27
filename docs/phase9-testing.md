# Fase 9: Small Field

Pulsa F durante Play para previsualizar Small Field; R gira la pieza y el clic
solicita su colocación. El servidor exige una posición libre y 50 monedas.
Al colocarlo añade un segundo `CropSlot` en la misma parcela. Sus semillas
pertenecen al mismo jugador y ambos espacios usan `CropService`.

`node tests/run.mjs` cubre colocación, propiedad, semillas compartidas,
crecimiento, cosecha en ambos espacios y bloqueo de superposición.

En Studio mediante MCP: Small Field costó 50 monedas, creó el segundo slot;
se plantó y cosechó Carrot en ambos. Inventario total 2, semillas restantes 8,
monedas 50. Output sin errores. Play detenido.
