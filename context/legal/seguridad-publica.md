# Seguridad pública

En Colombia los drones son también un arma. Grupos armados ilegales los usan con explosivos contra la fuerza pública:

- Según el Ministerio de Defensa, en 2025 hubo 195 ataques.
- Un estudio de la Universidad de los Andes cuenta más de 700 ataques acumulados.
- En 2025, los ministerios de Defensa, TIC y Transporte radicaron un proyecto de ley que crea un registro nacional de drones y de sistemas anti-dron y fija sanciones. Su aprobación no está confirmada.

Para una red de drones médicos, esto tiene dos consecuencias: un dron no identificado cerca de una instalación militar o de policía puede ser derribado, y la red debe poder demostrar en todo momento qué es cada vuelo.

## Qué hace AirDrop

| Medida | Para qué | Dónde |
| --- | --- | --- |
| 2 km de margen alrededor de bases, brigadas, cárceles e infraestructura crítica | Nunca acercarse a lo que se protege | [espacio-aereo.md](../operacion/espacio-aereo.md) |
| Estación de policía municipal como zona coordinada | El dron llega solo por el corredor acordado con esa estación | [espacio-aereo.md](../operacion/espacio-aereo.md) |
| Manifiesto de carga numerado | Demostrar qué lleva cada vuelo y quién lo autorizó | [manifiesto.md](../operacion/manifiesto.md) |
| Identificación remota de cada dron | Distinguir un vuelo de AirDrop de un contacto no identificado | [manifiesto.md](../operacion/manifiesto.md) |
| Restricciones temporales desde la consola | Cerrar una zona por orden público, un operativo, un evento (Festival Vallenato) o una jornada electoral | Zona `TEMPORAL` |
| Carga sellada con evidencia de manipulación | Que lo que llegó sea lo que salió | [../entregas/productos.md](../entregas/productos.md) |
| Protocolo de pérdida de enlace | Que un dron sin enlace no quede a la deriva | [contingencias.md](../operacion/contingencias.md) |

## Lo que AirDrop no hace

- No detecta ni neutraliza drones ajenos: eso es de la fuerza pública. El radar solo muestra el contacto no identificado y alerta si se acerca a un corredor.
- No comparte la telemetría con autoridades. Una operación real lo acordaría con la Aerocivil y la fuerza pública.
- No transporta nada que no esté en el inventario de una central, con lote y remisión.
