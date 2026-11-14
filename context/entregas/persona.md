# Entrega a una persona

Esto es dispensación: hay un paciente. La norma está en [../legal/salud.md](../legal/salud.md). Los tipos de producto y la cuarentena están en [productos.md](productos.md).

## El punto de entrega

El dron no llega a la puerta de nadie. En zona urbana la norma solo permite volar con el dron a la vista y a 30 m de personas y edificios (RAC 100.220(b)). Por eso entrega en un **punto de entrega autorizado**:

- un puesto de salud o dronpuerto de un corregimiento o municipio ([../negocio/cobertura.md](../negocio/cobertura.md));
- con un área despejada y un **observador** que mantiene el dron a la vista en la aproximación final y aleja a las personas a 30 m;
- fuera de toda zona prohibida, o con corredor pactado si está en una zona coordinada ([../operacion/espacio-aereo.md](../operacion/espacio-aereo.md)).

El punto no dispensa: custodia y entrega. La dispensación la hace el despachador del nodo antes de cargar.

La app toma el GPS del solicitante y le **propone el punto activo más cercano**. Puede elegir otro de la lista o del mapa.

- Si su ubicación está en la ciudad de Valledupar (zona urbana, dentro del anillo del aeropuerto), la app le dice que ahí no se opera con dron y le muestra la **alternativa terrestre** (RF-18): las centrales con el insumo, con dirección y contacto.
- Si no hay un punto al alcance de ningún nodo, pasa lo mismo.

## Pasos

1. El solicitante crea la urgencia o el plan periódico hacia un punto de entrega. En el plan elige días, hora de la franja y cuándo termina (RU-30); cada entrega le pide confirmar el día anterior.
2. **El paciente y la fórmula.** El paciente es el titular o una persona a su cargo (RF-42). En la urgencia, el solicitante puede responder el tamizaje (RF-41); responderlo es opcional. Si el ítem es de venta bajo fórmula, adjunta un PDF o de 1 a 3 fotos. El pedido no se crea si falta la fórmula o el documento del paciente, o si el ítem es de control especial.
3. **El despachador del nodo que tiene el insumo** lee el tamizaje y verifica la fórmula. Si falla algo, no autoriza.
   - Revisa que esté en español, legible y sin tachones.
   - Revisa que traiga genérico, concentración, forma, vía, dosis, frecuencia, duración y cantidad en números y letras.
   - Revisa que el paciente (nombre y documento) sea el del pedido, y la fecha, la vigencia y el registro de quien prescribe.
   - Mira también la edad, el embarazo y las alergias.
4. Confronta eso con el estante. Autorizar reserva el dron. El vuelo no empieza y el inventario no se descuenta.
5. **Confirmación de la carga.** El despachador registra la salida (paciente, medicamento, lote, cantidad y punto) y la información de uso que va con el paquete. Se emite el manifiesto ([../operacion/manifiesto.md](../operacion/manifiesto.md)) y se descuenta el lote de vencimiento más próximo.
6. **En el punto.** El código de un uso que ingresa el solicitante (también cuando el paciente es una persona a su cargo) cierra `entregado`. El dron espera 1 minuto para que retiren el medicamento y después vuelve vacío a su nodo.
7. Si en 5 minutos no hay código válido, el paquete vuelve y pasa por la cuarentena.

La urgencia no espera el plazo de 48 horas del canal EPS. Sale cuando el nodo ya verificó y cargó, y si hay luz del día ([../operacion/condiciones-de-vuelo.md](../operacion/condiciones-de-vuelo.md)).
