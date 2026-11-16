# Context

Fuente de verdad de AirDrop. Si el código y esta carpeta no coinciden, manda esta carpeta. La regla `.claude/rules/business-docs.md` obliga a detenerse y preguntar cuando un cambio se sale de aquí.

En esta raíz solo está este índice. El resto vive en carpetas. Cada carpeta responde una sola pregunta:

| Carpeta | Pregunta |
| --- | --- |
| `negocio/` | Para quién es, quién paga y dónde opera |
| `app/` | Quién usa el sistema y qué puede pedir |
| `entregas/` | Cómo viaja cada tipo de pedido |
| `operacion/` | Cómo vuela de verdad: flota, espacio aéreo, condiciones, contingencias |
| `legal/` | Qué norma lo permite o lo prohíbe |
| `producto/` | Qué se construye: alcance, requisitos, casos de uso, backlog |
| `calidad/` | Seguridad, rendimiento y usabilidad |
| `diseno/` | Cómo está armado el software y cómo se programa |
| `sustentacion/` | Cómo se defiende ante el jurado |
| `historial/` | Bitácoras del equipo. **No es especificación** |

## Dónde buscar

| Pregunta | Archivo |
| --- | --- |
| Clientes, quién paga y propuesta de valor | [negocio/modelo.md](negocio/modelo.md) |
| Nodos, ESE, puntos de entrega y alcance | [negocio/cobertura.md](negocio/cobertura.md) |
| Quién es cada rol y cómo entra | [app/roles.md](app/roles.md) |
| Qué puede viajar, lote, frío y cuarentena | [entregas/productos.md](entregas/productos.md) |
| Entrega a una persona | [entregas/persona.md](entregas/persona.md) |
| Traslado entre centrales | [entregas/centrales.md](entregas/centrales.md) |
| Tipos de dron y cómo elige el motor | [operacion/flota.md](operacion/flota.md) |
| Por dónde se puede volar | [operacion/espacio-aereo.md](operacion/espacio-aereo.md) |
| Luz del día, clima, altura y terreno | [operacion/condiciones-de-vuelo.md](operacion/condiciones-de-vuelo.md) |
| Incidentes en vuelo y pérdida de enlace | [operacion/contingencias.md](operacion/contingencias.md) |
| Manifiesto de carga e identificación del dron | [operacion/manifiesto.md](operacion/manifiesto.md) |
| Norma de drones (RAC 100) | [legal/aeronautica.md](legal/aeronautica.md) |
| Drones, orden público y restricciones | [legal/seguridad-publica.md](legal/seguridad-publica.md) |
| Qué se simula, qué queda fuera y qué falta verificar | [legal/cumplimiento.md](legal/cumplimiento.md) |
| Norma de medicamentos | [legal/salud.md](legal/salud.md) |
| Datos, consentimiento y seguridad | [legal/datos.md](legal/datos.md) |
| Qué entra en el MVP | [producto/alcance.md](producto/alcance.md) |
| Requisitos y su fundamento | [producto/requisitos.md](producto/requisitos.md) |
| Casos de uso | [producto/casos-de-uso.md](producto/casos-de-uso.md) |
| Historias y sprints | [producto/backlog.md](producto/backlog.md) |
| Controles de seguridad y riesgos aceptados | [calidad/seguridad.md](calidad/seguridad.md) |
| Límites del despliegue y cómo se mide | [calidad/rendimiento.md](calidad/rendimiento.md) |
| Accesibilidad, conexión rural y lenguaje | [calidad/usabilidad.md](calidad/usabilidad.md) |
| Cómo está armado el software | [diseno/arquitectura.md](diseno/arquitectura.md) |
| Cómo se programa | [diseno/principios.md](diseno/principios.md) |
| Problema, objetivos, marco, glosario, fuentes | [sustentacion/](sustentacion/) |

## Historial

Registran lo que pasó y lo que falta. Si chocan con la especificación, manda la especificación.

| Bitácora | Archivo |
| --- | --- |
| En qué fase va el frontend y qué historias están hechas | [historial/avance.md](historial/avance.md) |
| Qué le falta al backend frente al contexto | [historial/pendientes-backend.md](historial/pendientes-backend.md) |

## Orden si el cambio toca comportamiento

1. `app/roles.md`
2. La carpeta `entregas/` que corresponda
3. `operacion/` si el cambio toca cómo, cuándo o por dónde vuela el dron
4. `legal/` si el cambio toca datos, consentimiento o una prohibición
5. `producto/requisitos.md` y `producto/casos-de-uso.md`
