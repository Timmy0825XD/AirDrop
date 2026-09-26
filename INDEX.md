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

Detalle, cifras y justificación: [`context/sustentacion/problema.md`](context/sustentacion/problema.md).

---

## 3. Objetivo

### General

Desarrollar una aplicación móvil de logística aérea autónoma simulada que gestione, de forma inteligente, la **disponibilidad de la flota** y el **cálculo de rutas seguras** para misiones de emergencia y programadas, mejorando el acceso a tratamiento e insumos donde la distancia es el obstáculo principal.

### Específicos

1. Analizar requerimientos (solicitante, despachador, operador de flota).
2. Diseñar e implementar el **motor de simulación** y el **motor de decisión**, con parámetros distintos por tipo de misión (batería, carga, geovallas, rutas), con arquitectura clara y defendible.
3. Validar con pruebas funcionales y de integración el ciclo: solicitud → autorización → asignación de dron → carga del insumo → vuelo simulado → código de entrega o retorno.

Objetivos ampliados: [`context/sustentacion/objetivos.md`](context/sustentacion/objetivos.md).

---

## 4. Qué entra en el MVP (y qué no)

**Sí (Valledupar + 1–2 zonas cercanas):** pedidos de emergencia y programados, a una persona o entre centrales ([`context/entregas/`](context/entregas/)), flota simulada, geovallas, motor de decisión al autorizar, confirmación de carga antes del despegue, rutas por corredores a altitud fija, telemetría en vivo, espera de código de entrega (5 min) o retorno con el paquete, cadena de frío simulada, fallback, dashboard epidemiológico simple.

**No:** dron real, clima real, navegación 3D, multi-ciudad desplegada, integración hospitalaria, reemplazar la atención médica ni el traslado del paciente.

Alcance completo: [`context/producto/alcance.md`](context/producto/alcance.md).

---

## 5. Actores

| Rol | Función |
| --- | --- |
| **Solicitante** | Persona civil. Única cuenta que se autoregistra. Pide urgencias y entregas periódicas a su ubicación. |
| **Despachador** | Persona de **una** central, creada por el admin. Inventario, autoriza, carga y puede pedir abastecimiento a otra central. |
| **Operador de flota** | Persona creada por el admin. Drones, geovallas, telemetría y mantenimiento de **una o varias** centrales. |
| **Administrador** | Crea y suspende centrales y sus cuentas. Ve métricas. No despacha. |

La central es el lugar, no un rol. No hay rol de **receptor**. Detalle: [`context/app/roles.md`](context/app/roles.md).

---

## 6. Cómo está pensado el sistema

```
App Flutter (un solo código: tres roles operativos + admin)
        │  HTTPS + WSS
        ▼
Backend NestJS (módulos por dominio, no microservicios)
        ├── PostgreSQL + PostGIS   → lo que persiste (pedidos, flota, geovallas…)
        └── Redis                  → telemetría en vivo (posición, batería, fase)
```

Piezas de valor (las que hay que poder explicar en la sustentación):

1. **Motor de decisión** — al autorizar el despachador, elige el mejor dron y **no** inicia el vuelo: muestra la referencia para cargar el insumo. Emergencia gana si hay competencia.
2. **Cálculo de rutas** — corredores a altitud fija; no se cruza una geovalla.
3. **Motor de simulación** — “reloj” del backend: arranca **después** de confirmar la carga; en destino espera el código o regresa con el paquete.
4. **Fallback** — si no hay dron, hay alternativa, no un rechazo ciego.

Stack y conceptos: [`context/diseno/arquitectura.md`](context/diseno/arquitectura.md).  
Cómo programamos (simple + SOLID, sin arquitectura de tesis): [`context/diseno/principios.md`](context/diseno/principios.md).

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

## 8. Context

El mapa está en [`context/index.md`](context/index.md). En esa carpeta no hay otros markdown sueltos: roles, entregas, norma, producto, diseño y sustentación viven en subcarpetas.

---

## 9. Equipo y método

Scrum, 6 sprints de 2 semanas (1 sep – 22 nov 2026), 227 SP.

| Rol Scrum | Persona | Enfoque técnico |
| --- | --- | --- |
| Product Owner | Oscar Duque | Frontend |
| Scrum Master | Josheph Martínez | Backend |
| Development Team | Oscar Duque, Josheph Martínez, Sebastian Carrillo | Carrillo: mapa en tiempo real y WebSockets |

Detalle: [`context/producto/backlog.md`](context/producto/backlog.md).

---

## 10. Principio rector (para la sustentación)

Profesional y ordenado. **No** microservicios, **no** capas extra “por si acaso”, **no** DDD pesado. Módulos NestJS por dominio, app Flutter por características, principios SOLID **visibles** en el código (una responsabilidad por servicio, dependencias claras, reglas de decisión en un solo lugar). Quien lea el repo debe poder explicar el flujo de una misión en un diagrama y encontrarlo en el código sin perderse.
