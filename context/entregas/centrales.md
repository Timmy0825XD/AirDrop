# Traslado entre centrales

Esto es distribución física, no dispensación. No hay fórmula de paciente ni consejo de uso para un ciudadano. Hay una remisión de unidades selladas. La norma está en [../legal/salud.md](../legal/salud.md). Lote, frío y cuarentena están en [productos.md](productos.md).

Lo pide el despachador de la central que **necesita** el insumo. Lo suelta el despachador de la central que **lo tiene**. El dron sale de la segunda.

1. El despachador de destino elige la central de origen, el medicamento y la cantidad. Si el pedido es programado, también la frecuencia y la fecha de inicio. No adjunta fórmula.
2. El despachador de origen confirma unidades selladas del mismo genérico, concentración y forma. Arma la remisión: origen, destino, medicamento, lote, vencimiento y cantidad. Autorizar reserva el dron. El vuelo no empieza.
3. Al confirmar la carga descuenta ese lote en origen. No adjunta información de uso para un paciente: quien recibe es otro servicio de la red.
4. En destino, el despachador que pidió ingresa el código y compara la remisión: cantidad, lote, vencimiento, sello y, si el ítem lleva frío, la temperatura del trayecto.
5. Si todo coincide y no hubo alerta de frío, el inventario entra en la central de destino.
6. Si no hay código, la cantidad no coincide, el sello está mal o hubo alerta de temperatura, no entra. El paquete vuelve a origen y sigue la cuarentena.

Una central del simulador no le vende al detal a otra. El control especial no usa este camino: el pedido se rechaza, porque en la práctica ese movimiento pertenece al Fondo Nacional de Estupefacientes.
