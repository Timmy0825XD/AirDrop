# Principios de diseño

Documento global. Define **cómo** se construye AirDrop para que sea profesional, SOLID y **sustentable** (fácil de explicar). Los `AGENTS.md` de frontend y backend aplican estas reglas a su stack.

---

## 1. Criterio de oro

Si una decisión de diseño no se puede explicar en la sustentación en menos de un minuto, probablemente es demasiada.

Preguntas antes de añadir una capa, librería o patrón:

1. ¿Resuelve un requisito de [`requisitos.md`](requisitos.md) o un caso de uso de [`casos-de-uso.md`](casos-de-uso.md)?
2. ¿El equipo de tres personas puede mantenerlo en 6 sprints?
3. ¿Un profesor puede seguir el flujo de una misión en el código?

Si alguna respuesta es no, no se implementa.

---

## 2. Monorepo, dos aplicaciones

Una sola raíz de git.

| Carpeta | Qué es | Qué no es |
| --- | --- | --- |
| `frontend/` | Una app Flutter (Android e iOS), todos los roles | Varias apps, un panel web |
| `backend/` | Una API NestJS | Varios servicios desplegables |

Comparten el **contrato** (HTTP + WebSocket) y el **vocabulario** del [`glosario.md`](glosario.md). No comparten código de UI ni de ORM.

La arquitectura prevista multi-ciudad (varias centrales, varios drones) se **modela** (entidades `City` / `Hub` opcionales o un `hubId` en drones) sin desplegar N ciudades en el MVP.

---

## 3. Dominios (el mapa mental)

Los mismos nombres en backend (módulos Nest) y, en lo posible, en frontend (features):

1. **Auth** — registro, OTP, JWT, roles.
2. **Hubs (centrales)** — registro, aprobación, perfil.
3. **Inventory** — existencias, vencimiento, cadena de frío (flag).
4. **Fleet** — drones, `DroneModel`, estados, mantenimiento.
5. **Geofences** — polígonos PostGIS.
6. **Orders** — emergencia y programados, estados, código de entrega.
7. **Decision** — elegibilidad + prioridad emergencia > programado.
8. **Routing** — corredores a altitud fija evitando geovallas.
9. **Simulation** — reloj, fases de vuelo, batería, temperatura simulada.
10. **Telemetry** — Redis + gateway WebSocket.
11. **Notifications** — push por cambio de estado y alertas.
12. **Analytics** — dashboard epidemiológico y métricas admin (consultas SQL, no un data warehouse).

No hace falta un “bounded context” formal ni eventos de dominio entre estos módulos: llamadas de servicio y, si hace falta, un `EventEmitter` de Nest **dentro del mismo proceso**.

---

## 4. SOLID aplicado (ejemplos concretos)

**S — Responsabilidad única**

- `EligibilityService`: responde “sí/no + motivo” dado un dron y una misión.
- `RoutePlannerService`: calcula polyline / waypoints o falla si no hay corredor.
- `FlightClockService`: avanza simulación en intervalos (RNF-08: ≤ 2 s).
- `FallbackService`: alternativa cuando elegibilidad es vacía (RF-18, CU-31).

**O — Abierto/cerrado**

- Tipos de misión (`emergency` | `scheduled`) como discriminador; las reglas extra de programados (agrupar entregas, calendario) viven en funciones aparte, no en un `if` de 200 líneas mezclado con el vuelo.

**D — Inversión de dependencias (ligera)**

- El reloj de simulación no habla con Flutter. Publica a un puerto mínimo: `publishTelemetry(droneId, snapshot)`.
- En Nest, ese puerto puede ser una clase `TelemetryPublisher` usada por el gateway. No se necesita interfaz por cada repositorio.

**Qué no es SOLID aquí:** crear 15 interfaces “por si cambiamos de base de datos”. El MVP usa PostgreSQL y Redis; se inyectan los repositorios concretos de TypeORM / el cliente Redis.

---

## 5. Datos: persistente vs en vivo

| Dónde | Qué |
| --- | --- |
| PostgreSQL + PostGIS | Pedidos, misiones históricas, inventario, geovallas, usuarios, configuración del dron |
| Redis | Snapshot de telemetría mientras hay misión activa; pub/sub hacia el gateway |

Al terminar la misión, un resumen (tiempos, incidencias de temperatura/batería) **sí** se persiste. No se vuelca cada tick de 2 s a Postgres.

---

## 6. Flujo que todo el código debe respetar

```
Pedido (emergencia o ocurrencia de un plan programado)
  → (si emergencia) despachador autoriza e inventario
  → Motor de decisión (batería, payload, mantenimiento, clima simulado, ruta)
       ├─ hay dron → calcular ruta → simular vuelo → telemetría → entrega / código
       └─ no hay dron → fallback (otra central o traslado convencional)
```

Emergencia **siempre** gana el dron si hay competencia (RF-11, HU-22, CU-26).

---

## 7. Calibración del dron (una entidad, no un simulador de física)

`DroneModel` (Wingcopter 198): velocidad máxima ~150 km/h, payload hasta 6 kg, alcance hasta 110 km con carga ligera. Consumo de batería **por fase**: despegue vertical, transición, crucero ala fija, descenso, aterrizaje.

No se modela aerodinámica, viento real ni colisiones 3D. Obstáculos = geovallas + banda de altitud fija.

---

## 8. Frontend: una app, navegación por rol

Tras el login, la UI muestra el **shell del rol**. Componentes compartidos: mapa, estados de pedido, notificaciones. No hay cuatro repositorios Flutter.

Mapa y WebSockets son críticos (sprint 5); deben quedar en un módulo de cliente de telemetría pequeño y reutilizable (solicitante, receptor, operador), no copiados.

---

## 9. Pruebas (suficientes para defender calidad)

- Unitarias: elegibilidad, prioridad, “ruta cruza geovalla”, gasto de batería por fase (números redondos, no un paper).
- Integración: registro → pedido → (mock de decisión) → estado.
- No se exige cobertura 100 % ni pirámide de testing corporativa.

---

## 10. Relación con los AGENTS.md

| Archivo | Autoridad |
| --- | --- |
| `INDEX.md` + este archivo + resto de `context/` | Negocio, alcance, diseño |
| `/AGENTS.md` | Disciplina de implementación global |
| `frontend/AGENTS.md` | Convenciones Flutter |
| `backend/AGENTS.md` | Convenciones NestJS |
