# Marco de referencia

## Conceptos (para hablar con precisión)

| Término | Significado en AirDrop |
| --- | --- |
| **eVTOL** | Aeronave eléctrica de despegue y aterrizaje vertical; crucero más eficiente que un multirrotor puro. El Colibrí y el Garza son de este tipo; el Cóndor es un multirrotor de carga. |
| **BVLOS** | Vuelo más allá de la línea de vista del operador (más de 3 km, RAC 100.445). Necesario en delivery a distancia. AirDrop simula sus reglas (corredor con 30 m de tolerancia, geocercas, telemetría visible, protocolo de enlace perdido), no el permiso. |
| **Motor de decisión** | Software que, con reglas y datos actuales, dice si una unidad puede cumplir la tarea **cuando el despachador autoriza**. Asigna el dron; el vuelo espera la confirmación de carga. Es el núcleo de inteligencia de AirDrop. |
| **Geovalla** | Perímetro virtual sobre coordenadas reales: restringe o permite movimiento. Aquí: polígonos que el enrutador no puede cruzar. |
| **DroneModel** | Configuración reutilizable (no cada dron suelto) con las specs de un tipo de dron. |
| **Corredor con perfil de terreno** | Sustituto simple de pathfinding 3D: se rodean las zonas en planta y la altura sigue el terreno entre 60 y 120 m AGL. |
| **Nodo y punto de entrega** | El modelo de Zipline: el dron sale de un centro de distribución y entrega en un sitio fijo y despejado, no en la puerta. |

## Antecedentes

**Zipline (Ruanda desde 2016, Ghana 2019):** sangre y medicamentos a hospitales rurales; red amplia (p. ej. 30 drones, 4 centros, ~2.000 centros de salud en el relato de 2019). Combina **rutina programada** (vacunas, sangre) y **urgencia bajo demanda** desde los mismos centros. AirDrop copia ese **modelo dual** a escala simulada y acotada al Caribe colombiano.

**Wingcopter y otros eVTOL médicos:** operaciones de vacunas, sangre y equipo médico. Sus fichas públicas dan los rangos de carga, velocidad y alcance de los tres tipos propios de AirDrop ([../operacion/flota.md](../operacion/flota.md)).

**Colombia:**

- Valencia-Arias et al. (2022): factores de adopción de drones para entrega en Medellín (COVID-19).
- Rodríguez (2025): viabilidad de drones para insumos médicos en Colombia; acceso oportuno como desafío en zonas difíciles; potencial de equidad sanitaria.
- Orkid S.A.S. (2025): primera empresa con permiso de la Aerocivil para entregas con dron, con foco en insumos médicos.
- RAC 100 (2023): el reglamento colombiano de drones ([../legal/aeronautica.md](../legal/aeronautica.md)).

AirDrop baja esa línea a un caso concreto: **urgencia + reabastecimiento** en la zona rural de Valledupar y los municipios vecinos, con software defendible y que respeta la norma, no con una flota real.

Glosario corto adicional: [`glosario.md`](glosario.md). Fuentes: [`fuentes.md`](fuentes.md).
