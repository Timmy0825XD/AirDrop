# Productos, lote y cuarentena

Reglas comunes a los dos caminos. El camino a una persona está en [persona.md](persona.md). El traslado entre centrales, en [centrales.md](centrales.md).

| Tipo | A una persona | Entre centrales |
| --- | --- | --- |
| Venta libre | Sin fórmula. Sí se informa almacenamiento, medición y cuidados | Unidades selladas, con lote y vencimiento |
| Venta bajo fórmula | Imagen de fórmula válida y documento de la cuenta igual al del paciente | Unidades selladas, con lote y vencimiento. La fórmula del paciente no viaja |
| Control especial | El pedido no se crea | El pedido no se crea |
| Cadena de frío | Viaja con monitoreo. Si la temperatura sale del rango, no se vuelve a usar | Igual. La central que recibe no lo ingresa si hubo alerta |

No sale vencido, abierto, reempacado ni sin lote. Si hay varios lotes del mismo producto, sale el que vence primero. No se cambia principio activo, concentración, forma, vía, dosis ni cantidad.

## Cuarentena

Si en 5 minutos nadie ingresa el código, el paquete vuelve a la central de origen.

- Sin alerta de temperatura, y con el empaque íntegro: puede reingresar al inventario de origen.
- Con alerta de temperatura, o si el despachador marca el empaque comprometido: no reingresa y no se vuelve a dispensar ni a trasladar.

Tras un incidente en vuelo (RF-34):

- Si el dron vuelve a la central con el paquete, el paquete queda en cuarentena: no reingresa. El pedido ya sigue con otro dron (RF-35), así que no pasa por la revisión del despachador.
- Si aterriza de emergencia, el paquete se recupera con el dron y queda en cuarentena: no reingresa.
- Con choque grave o dron perdido, el paquete se da por perdido.

Si la urgencia se vuelve a despachar, sale otro lote, que se descuenta al confirmar la carga.

En un traslado que sí se recibe, el inventario entra en la central de destino solo si la remisión coincide y no hubo alerta de frío. Si no coincide, no entra: vuelve a origen y aplica la misma cuarentena.
