# Marco de referencia

## Conceptos (para hablar con precisión)

| Término | Significado en AirDrop |
| --- | --- |
| **eVTOL** | Aeronave eléctrica de despegue y aterrizaje vertical; crucero más eficiente que un multirrotor puro. El Wingcopter 198 es un eVTOL de rotor basculante usado en entrega médica real. |
| **BVLOS** | Vuelo más allá de la línea de vista del operador. Necesario en delivery a distancia; reto regulatorio en el mundo real. En el MVP solo se **simula** la misión, no se opera BVLOS legal. |
| **Motor de decisión** | Software que, con reglas y datos actuales, dice si una unidad puede cumplir la tarea **antes** de asignarla. Es el núcleo de inteligencia de AirDrop. |
| **Geovalla** | Perímetro virtual sobre coordenadas reales: restringe o permite movimiento. Aquí: polígonos que el enrutador no puede cruzar. |
| **DroneModel** | Configuración reutilizable (no cada dron suelto) con specs tipo Wingcopter 198. |
| **Corredor a altitud fija** | Sustituto simple de pathfinding 3D: se vuela a una banda de altura y se rodean geovallas en 2D. |

## Antecedentes

**Zipline (Ruanda desde 2016, Ghana 2019):** sangre y medicamentos a hospitales rurales; red amplia (p. ej. 30 drones, 4 centros, ~2.000 centros de salud en el relato de 2019). Combina **rutina programada** (vacunas, sangre) y **urgencia bajo demanda** desde los mismos centros. AirDrop copia ese **modelo dual** a escala simulada y acotada al Caribe colombiano.

**Wingcopter:** operaciones de vacunas, sangre y equipo médico; uso público de simulación para alcance y carga. Base técnica del `DroneModel`.

**Colombia:**

- Valencia-Arias et al. (2022): factores de adopción de drones para entrega en Medellín (COVID-19).
- Rodríguez (2025): viabilidad de drones para insumos médicos en Colombia; acceso oportuno como desafío en zonas difíciles; potencial de equidad sanitaria.

AirDrop baja esa línea a un caso concreto: **urgencia + reabastecimiento** en Valledupar y zona cercana, con software defendible, no con una flota real.

Glosario corto adicional: [`glosario.md`](glosario.md). Fuentes: [`fuentes.md`](fuentes.md).
