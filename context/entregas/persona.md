# Entrega a una persona

Esto es dispensación: hay un paciente. La norma está en [../legal/salud.md](../legal/salud.md). Los tipos de producto y la cuarentena están en [productos.md](productos.md).

1. El solicitante crea la urgencia o el plan periódico hacia su ubicación. En el plan elige días, hora de la franja y cuándo termina (RU-30); cada entrega le pide confirmar el día anterior.
2. El paciente es el titular o una persona a su cargo (RF-42); en la urgencia, el solicitante responde el tamizaje (RF-41). Si el ítem es de venta bajo fórmula, adjunta un PDF o de 1 a 3 fotos. El pedido no se crea si falta la fórmula o el documento del paciente, o si el ítem es de control especial.
3. El despachador de la central que tiene el insumo lee el tamizaje y verifica la fórmula: español, legible, sin tachones, con genérico, concentración, forma, vía, dosis, frecuencia, duración, cantidad en números y letras, paciente (nombre y documento iguales a los del pedido), fecha, vigencia y registro de quien prescribe. Mira también la edad, el embarazo y las alergias. Si falla, no autoriza.
4. Confronta eso con el estante. Autorizar reserva el dron. El vuelo no empieza y el inventario no se descuenta.
5. Al confirmar la carga registra la salida (paciente, medicamento, lote, cantidad, destino) y la información de uso que va con el paquete. Ahí se descuenta el lote de vencimiento más próximo.
6. En destino, el código de un uso que ingresa el solicitante (también cuando el paciente es una persona a su cargo) cierra `entregado`. El dron espera 1 minuto en el punto para que retiren el medicamento y después vuelve vacío a su central.
7. Si en 5 minutos no hay código válido, el paquete vuelve y pasa por la cuarentena.

La urgencia no espera el plazo de 48 horas del canal EPS. Sale cuando la central ya verificó y cargó.
