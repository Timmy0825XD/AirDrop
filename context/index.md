# Context

Fuente de verdad de AirDrop. Si el código y esta carpeta no coinciden, manda esta carpeta. La regla `.cursor/rules/business-docs.mdc` obliga a detenerse y preguntar cuando un cambio se sale de aquí.

En esta raíz solo está este índice. El resto vive en carpetas.

## Dónde buscar

| Pregunta | Archivo |
| --- | --- |
| Quién es cada rol y cómo entra | [app/roles.md](app/roles.md) |
| Qué puede viajar, lote, frío y cuarentena | [entregas/productos.md](entregas/productos.md) |
| Entrega a una persona | [entregas/persona.md](entregas/persona.md) |
| Traslado entre centrales | [entregas/centrales.md](entregas/centrales.md) |
| Norma de medicamentos | [legal/salud.md](legal/salud.md) |
| Datos, consentimiento y seguridad | [legal/datos.md](legal/datos.md) |
| Qué entra en el MVP | [producto/alcance.md](producto/alcance.md) |
| Requisitos y su fundamento | [producto/requisitos.md](producto/requisitos.md) |
| Casos de uso | [producto/casos-de-uso.md](producto/casos-de-uso.md) |
| Historias y sprints | [producto/backlog.md](producto/backlog.md) |
| Cómo está armado el software | [diseno/arquitectura.md](diseno/arquitectura.md) |
| Cómo se programa | [diseno/principios.md](diseno/principios.md) |
| Problema, objetivos, marco, glosario, fuentes | [sustentacion/](sustentacion/) |

## Orden si el cambio toca comportamiento

1. `app/roles.md`
2. La carpeta `entregas/` que corresponda
3. `legal/` si el cambio toca datos, consentimiento o una prohibición
4. `producto/requisitos.md` y `producto/casos-de-uso.md`
