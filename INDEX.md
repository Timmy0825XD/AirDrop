# AirDrop

Aplicación **móvil** de logística aérea autónoma **simulada**. Entrega medicamentos y suministros médicos en zonas donde la distancia (y no la falta de inventario en el sistema de salud) es el obstáculo.

Este archivo es el **índice raíz** del repositorio: objetivo, esencia y mapa de documentos. El detalle vive en [`context/`](context/). Las reglas de implementación viven en [`AGENTS.md`](AGENTS.md) (globales) y en `frontend/AGENTS.md` / `backend/AGENTS.md` (específicas, siempre alineadas con el contexto global).

---

## 1. En una frase

AirDrop decide **qué central** despacha, **qué dron** puede cumplir la misión y **qué ruta** es segura, para dos tipos de servicio: **emergencia** (bajo demanda, prioridad máxima) y **reabastecimiento programado** (sangre, vacunas y otros insumos). Si ningún dron es viable, el sistema **sugiere una alternativa** en lugar de rechazar el pedido.

No es un dron aislado: es un **sistema de decisión** más un **motor de simulación** calibrado con el [Wingcopter 198](https://wingcopter.com/). No hay hardware real ni aplicación web.

---

## 2. Problema que resolvemos

En la región Caribe colombiana (caso de estudio: **Valledupar** y municipios o corregimientos cercanos) el medicamento a menudo está en un lugar distinto al paciente o al centro de salud. El traslado terrestre es lento, a veces inseguro, y convierte el desabastecimiento en urgencias evitables.

Pregunta del proyecto:

> ¿Cómo mejorar el acceso a medicamentos y suministros médicos, en urgencia puntual y en abastecimiento programado, con un sistema autónomo de decisión y logística que **no dependa de la vía terrestre**?

Detalle, cifras y justificación: [`context/problema-y-justificacion.md`](context/problema-y-justificacion.md).

---

## 3. Objetivo

### General

Desarrollar una aplicación móvil de logística aérea autónoma simulada que gestione, de forma inteligente, la **disponibilidad de la flota** y el **cálculo de rutas seguras** para misiones de emergencia y programadas, mejorando el acceso a tratamiento e insumos donde la distancia es el obstáculo principal.

### Específicos

1. Analizar requerimientos (solicitante, despachador, operador de flota, receptor).
2. Diseñar e implementar el **motor de simulación** y el **motor de decisión**, con parámetros distintos por tipo de misión (batería, carga, geovallas, rutas), con arquitectura clara y defendible.
3. Validar con pruebas funcionales y de integración el ciclo: solicitud → asignación → vuelo simulado → entrega.

Objetivos ampliados: [`context/objetivos.md`](context/objetivos.md).

---

## 4. Qué entra en el MVP (y qué no)

**Sí (Valledupar + 1–2 zonas cercanas):** pedidos de emergencia y programados, flota simulada, geovallas, motor de decisión, rutas por corredores a altitud fija, telemetría en vivo, cadena de frío simulada, fallback de entrega, dashboard epidemiológico simple.

**No:** dron real, clima real, navegación 3D, multi-ciudad desplegada, integración hospitalaria, reemplazar la atención médica ni el traslado del paciente.

Alcance completo: [`context/alcance-y-limitaciones.md`](context/alcance-y-limitaciones.md).

---

## 5. Actores

| Rol | Función |
| --- | --- |
| **Solicitante** | Reporta la urgencia o el pedido y sigue el vuelo. |
| **Despachador** | Inventario de la central, autoriza despacho, crea planes programados. |
| **Operador de flota** | Drones, geovallas, telemetría, mantenimiento. |
| **Receptor** | Confirma la entrega (con o sin cuenta, vía código). |
| **Administrador** | Aprueba centrales, gestiona cuentas institucionales, métricas. |

Negocio y propuesta de valor: [`context/actores-y-modelo-de-negocio.md`](context/actores-y-modelo-de-negocio.md).

---

## 6. Cómo está pensado el sistema

```
App Flutter (un solo código, cuatro roles + admin)
        │  HTTPS + WSS
        ▼
Backend NestJS (módulos por dominio, no microservicios)
        ├── PostgreSQL + PostGIS   → lo que persiste (pedidos, flota, geovallas…)
        └── Redis                  → telemetría en vivo (posición, batería, fase)
```

Piezas de valor (las que hay que poder explicar en la sustentación):

1. **Motor de decisión** — ¿puede este dron cumplir esta misión? Emergencia gana si hay competencia.
2. **Cálculo de rutas** — corredores a altitud fija; no se cruza una geovalla.
3. **Motor de simulación** — “reloj” del backend: mueve el dron, gasta batería por fase de vuelo (eVTOL).
4. **Fallback** — si no hay dron, hay alternativa, no un rechazo ciego.

Stack y conceptos: [`context/arquitectura-tecnologica.md`](context/arquitectura-tecnologica.md).  
Cómo programamos (simple + SOLID, sin arquitectura de tesis): [`context/principios-de-diseno.md`](context/principios-de-diseno.md).

---

## 7. Cómo se organiza este repositorio

Monorepo **deliberadamente plano**. Dos aplicaciones, un contexto compartido.

```
INDEX.md                 ← estás aquí (objetivo e índice)
AGENTS.md                ← reglas globales para quien implemente (humano o agente)
README.md                ← entrada corta del repositorio
context/                 ← esencia del proyecto (fuente de verdad de negocio y diseño)
frontend/                ← app Flutter (reglas en frontend/AGENTS.md)
backend/                 ← API NestJS (reglas en backend/AGENTS.md)
```

Los `AGENTS.md` de frontend y backend **no inventan** reglas de negocio: las aplican. Si hay conflicto, ganan `INDEX.md` y `context/`.

---

## 8. Índice de documentos (`context/`)

| Documento | Para qué abrirlo |
| --- | --- |
| [problema-y-justificacion.md](context/problema-y-justificacion.md) | Problema, cifras, por qué existe AirDrop |
| [objetivos.md](context/objetivos.md) | Objetivo general y específicos |
| [alcance-y-limitaciones.md](context/alcance-y-limitaciones.md) | MVP, fuera de alcance |
| [actores-y-modelo-de-negocio.md](context/actores-y-modelo-de-negocio.md) | Roles, canvas de negocio |
| [marco-de-referencia.md](context/marco-de-referencia.md) | Conceptos (eVTOL, BVLOS, geovalla) y antecedentes (Zipline, Colombia) |
| [arquitectura-tecnologica.md](context/arquitectura-tecnologica.md) | Flutter, NestJS, Postgres/PostGIS, Redis, WebSockets, simulación |
| [principios-de-diseno.md](context/principios-de-diseno.md) | Simplicidad, SOLID, qué no hacer |
| [requisitos.md](context/requisitos.md) | RU, RF, RNF |
| [product-backlog.md](context/product-backlog.md) | Historias, sprints, incrementos, cronograma |
| [casos-de-uso.md](context/casos-de-uso.md) | CU-01 a CU-32 |
| [glosario.md](context/glosario.md) | Vocabulario del proyecto |
| [fuentes.md](context/fuentes.md) | Referencias del documento base |

---

## 9. Equipo y método

Scrum, 6 sprints de 2 semanas (1 sep – 22 nov 2026), 227 SP.

| Rol Scrum | Persona | Enfoque técnico |
| --- | --- | --- |
| Product Owner | Oscar Duque | Frontend |
| Scrum Master | Josheph Martínez | Backend |
| Development Team | Oscar Duque, Josheph Martínez, Sebastian Carrillo | Carrillo: mapa en tiempo real y WebSockets |

Detalle: [`context/product-backlog.md`](context/product-backlog.md).

---

## 10. Principio rector (para la sustentación)

Profesional y ordenado. **No** microservicios, **no** capas extra “por si acaso”, **no** DDD pesado. Módulos NestJS por dominio, app Flutter por características, principios SOLID **visibles** en el código (una responsabilidad por servicio, dependencias claras, reglas de decisión en un solo lugar). Quien lea el repo debe poder explicar el flujo de una misión en un diagrama y encontrarlo en el código sin perderse.
