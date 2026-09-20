# AGENTS.md — reglas globales (AirDrop)

Este archivo aplica a **todo** el monorepo. Las reglas de [`frontend/AGENTS.md`](frontend/AGENTS.md) y [`backend/AGENTS.md`](backend/AGENTS.md) lo especializan; no lo contradicen.

Antes de implementar o cambiar comportamiento de negocio, leer:

1. [`INDEX.md`](INDEX.md)
2. [`context/principios-de-diseno.md`](context/principios-de-diseno.md)
3. El documento de `context/` que corresponda (pedidos, flota, rutas, etc.)

---

## Fuente de verdad

- El **qué** y el **por qué** están en `context/`.
- El **cómo de código** (nombres de carpetas, frameworks) está en los `AGENTS.md` de cada lado.
- Si un detalle de implementación choca con un requisito o un caso de uso, **gana el contexto**, no la conveniencia del código.

---

## Complejidad permitida

AirDrop se **sustenta**. El código debe verse profesional y ser fácil de explicar.

**Hacer**

- Un módulo (Nest) o una feature (Flutter) por dominio de negocio: autenticación, centrales, inventario, flota, geovallas, pedidos, decisión, rutas, simulación/telemetría, entregas, métricas.
- Servicios con una responsabilidad clara (p. ej. `EligibilityService` decide; `FlightSimulationService` mueve el dron; `TelemetryGateway` publica).
- Reglas de negocio en código explícito (if/funciones con nombre), no en un “framework” interno.
- Tests del camino feliz y de los bordes que importan: emergencia vs programado, dron no elegible → fallback, geovalla bloquea ruta, **no hay vuelo sin confirmar carga**, código a tiempo vs timeout de 5 min → retorno con paquete.

**No hacer**

- Microservicios, event buses, CQRS, hexagonal/clean con puertos y adaptadores en cada módulo.
- Repositorios genéricos de 4 niveles, factories de factories, “engine plugins”.
- Abstracciones para un segundo modelo de dron que no existe en el MVP (hoy el modelo es Wingcopter 198 vía `DroneModel`).
- App web, admin separado en otro framework, o un segundo canal de tiempo real además de WebSockets.

---

## SOLID, a escala de aula

| Principio | Cómo se ve aquí |
| --- | --- |
| S | Un servicio no simula y decide a la vez. |
| O | Nuevos tipos de misión se agregan extendiendo reglas, no copiando el motor. |
| L | Si hay interfaces, son pocas y reales (p. ej. “publicar telemetría”), no por costumbre. |
| I | No hay `IDroneManager` con 20 métodos. |
| D | El motor de decisión no importa TypeORM ni Flutter; recibe datos (DTOs / entidades de dominio simples). |

---

## Idioma y nombres

- Interfaz de usuario y copys: **español (Colombia)**.
- Código (clases, archivos, commits en inglés o español consistente): preferir **inglés** para identificadores (`Order`, `Drone`, `Geofence`).
- IDs de requisitos y casos de uso se conservan (`RF-11`, `CU-26`) en comentarios solo cuando aclaran un algoritmo no obvio.

---

## Seguridad mínima del MVP

- Contraseñas con bcrypt; JWT con expiración; autorización por **rol**.
- HTTPS / WSS en despliegue.
- Datos de salud: consentimiento explícito; no loguear payloads clínicos en texto plano.
- Límite de intentos de login (RNF-04).

Detalle: [`context/requisitos.md`](context/requisitos.md) (RNF).

---

## Git y cambios

- Git Flow + commits convencionales (`tipo(alcance): descripcion`). El agente **no** hace `commit`, `push` ni PR.
- No trabajar directo en `main` ni `develop`.
- No mezclar refactor cosmético con una historia de usuario.
- No ampliar el alcance del MVP “porque queda bonito” (multi-ciudad, clima real, 3D).
