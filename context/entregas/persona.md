# Entrega a una persona

Esto es dispensación: hay un paciente. La norma está en [../legal/salud.md](../legal/salud.md). Los tipos de producto y la cuarentena están en [productos.md](productos.md).

## Dónde llega el dron

El dron llega al **punto que marca el solicitante** en el mapa: su GPS ("Usar mi ubicación") o el pin, con una referencia corta opcional (RF-45). No hay puntos fijos de entrega.

- Si el punto no está al alcance de ningún nodo, la app le muestra la **alternativa terrestre** (RF-18): las centrales con el insumo, con dirección y contacto.
- Si el punto cae dentro de una zona prohibida ([../operacion/espacio-aereo.md](../operacion/espacio-aereo.md)), no hay corredor y sigue RF-18.

La dispensación la hace el despachador del nodo antes de cargar.

**Simplificación.** La norma pide un observador y 30 m de personas ajenas al aterrizar (RAC 100.220(b), 100.320). El MVP no lo verifica ([../legal/aeronautica.md](../legal/aeronautica.md)).

## Pasos

1. El solicitante crea la urgencia o el plan periódico hacia su ubicación. En el plan elige días, hora de la franja y cuándo termina (RU-30); cada entrega le pide confirmar el día anterior.
2. **El paciente y la fórmula.** El paciente es el titular o una persona a su cargo (RF-42). En la urgencia, el solicitante puede responder el tamizaje (RF-41); responderlo es opcional. Si el ítem es de venta bajo fórmula, adjunta un PDF o de 1 a 3 fotos. El pedido no se crea si falta la fórmula o el documento del paciente, o si el ítem es de control especial.
3. **El despachador del nodo que tiene el insumo** lee el tamizaje y verifica la fórmula. Si falla algo, no autoriza.
   - Revisa que esté en español, legible y sin tachones.
   - Revisa que traiga genérico, concentración, forma, vía, dosis, frecuencia, duración y cantidad en números y letras.
   - Revisa que el paciente (nombre y documento) sea el del pedido, y la fecha, la vigencia y el registro de quien prescribe.
   - Mira también la edad, el embarazo y las alergias.
4. Confronta eso con el estante. Autorizar reserva el dron. El vuelo no empieza y el inventario no se descuenta.
5. **Confirmación de la carga.** El despachador registra la salida (paciente, medicamento, lote, cantidad y destino) y la información de uso que va con el paquete. Se emite el manifiesto ([../operacion/manifiesto.md](../operacion/manifiesto.md)) y se descuenta el lote de vencimiento más próximo.
6. **En el destino.** El código de un uso que ingresa el solicitante (también cuando el paciente es una persona a su cargo) cierra `entregado`. El dron espera 1 minuto para que retiren el medicamento y después vuelve vacío a su nodo.
7. Si en 5 minutos no hay código válido, el paquete vuelve y pasa por la cuarentena.

La urgencia no espera el plazo de 48 horas del canal EPS. Sale cuando el nodo ya verificó y cargó, a cualquier hora (RF-44).
