# Entrega a una persona

Esto es dispensación: hay un paciente. La norma está en [../legal/salud.md](../legal/salud.md). Los tipos de producto y la cuarentena están en [productos.md](productos.md).

1. El solicitante crea la urgencia o el plan periódico hacia su ubicación.
2. Si el ítem es de venta bajo fórmula, adjunta la imagen. El pedido no se crea si falta la imagen, si el documento de la cuenta no es el del paciente, o si el ítem es de control especial.
3. El despachador de la central que tiene el insumo verifica la fórmula: español, legible, sin tachones, con genérico, concentración, forma, vía, dosis, frecuencia, duración, cantidad en números y letras, paciente, fecha, vigencia y registro de quien prescribe. Si falla, no autoriza.
4. Confronta eso con el estante. Autorizar reserva el dron. El vuelo no empieza y el inventario no se descuenta.
5. Al confirmar la carga registra la salida (paciente, medicamento, lote, cantidad, destino) y la información de uso que va con el paquete. Ahí se descuenta el lote de vencimiento más próximo.
6. En destino, el código de un uso que ingresa el solicitante cierra `entregado`.
7. Si en 5 minutos no hay código válido, el paquete vuelve y pasa por la cuarentena.

La urgencia no espera el plazo de 48 horas del canal EPS. Sale cuando la central ya verificó y cargó.
