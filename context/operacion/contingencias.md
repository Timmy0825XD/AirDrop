# Contingencias

Qué hace un dron cuando algo sale mal en vuelo. Los incidentes son de RF-34. El reloj de vuelo detecta algunos y la consola o el modo caos lanzan los demás (CU-38). Cada uno queda registrado con la hora, la posición, el dron y el pedido.

## Respuestas posibles

| Respuesta | Qué hace el dron |
| --- | --- |
| **Seguir** | Continúa la misión con la condición nueva (más consumo, menos velocidad) |
| **Regresar** | Vuelve al nodo por el corredor. Si lleva el paquete, el paquete vuelve y sigue la cuarentena ([../entregas/productos.md](../entregas/productos.md)) |
| **Aterrizar en punto seguro** | Va al punto seguro más cercano al que le alcance la batería: un nodo, una ESE o un punto de entrega |
| **Aterrizaje inmediato** | Baja donde está, fuera de cualquier zona prohibida. El dron queda fuera de servicio hasta que el operador lo recupere |

## Incidentes y respuesta

| Incidente | Respuesta |
| --- | --- |
| Batería crítica (bajo 20 %) | Aterrizar en punto seguro |
| Viento sobre el límite del tipo | Regresar, o aterrizar en punto seguro si no alcanza |
| Ruta bloqueada por una zona nueva (tormenta, niebla, restricción temporal) | Replanificar. Si no hay camino, regresar |
| La batería no alcanza el camino nuevo | Aterrizar en punto seguro |
| Batería degradada | Seguir, con más consumo |
| Falla de un motor | Seguir degradado, o regresar si la batería no alcanza con el consumo nuevo |
| Falla de dos motores | Aterrizaje inmediato |
| Pérdida menor de GPS | Seguir con el sistema de posición de respaldo |
| Pérdida mayor de GPS | Aterrizaje inmediato |
| **Pérdida del enlace C2** | Protocolo de enlace perdido (abajo) |
| Falla del frío | Seguir, con alerta de temperatura: la carga llega a cuarentena |
| Choque menor (ave u obstáculo) | Seguir, con más consumo |
| Choque mayor | Cae: fuera de servicio y paquete perdido |
| Dron perdido | Sin rastro: fuera de servicio y paquete perdido |

## Pérdida del enlace C2

El RAC 100.445 trata la pérdida o degradación del enlace de mando y control como una emergencia. El protocolo simulado:

1. **Espera 30 segundos** en vuelo estacionario o en círculo, a la misma altura, mientras intenta recuperar el enlace.
2. Si lo recupera, sigue la misión y el incidente queda registrado. En la demo el enlace vuelve en la mitad de los casos.
3. Si no, **regresa solo al nodo** por el corredor aprobado, a su altura de crucero.
4. Si la batería no alcanza para regresar, aterriza en el punto seguro más cercano.
5. Mientras no hay enlace, el radar pinta el dron en su última posición conocida, con el estado "sin enlace", y estima su recorrido.

## Lo que ve cada rol

- **Operador de flota:** el incidente, la respuesta que tomó el dron y dónde quedó.
- **Despachador:** si su pedido se retrasa, vuelve o se pierde.
- **Solicitante:** un mensaje sin detalle técnico ("tu pedido regresó al nodo; te avisaremos del nuevo envío").
- **Administrador:** todo, en el radar y en las métricas.
