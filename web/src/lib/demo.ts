import type { RadarHandlers, RadarSource } from "./source";
import type {
  ClockView,
  Corridor,
  FleetCounts,
  FlightDetail,
  HubDetail,
  HubSummary,
  InventoryRow,
  RadarFlight,
  Snapshot,
  TelemetryEvent,
  TimelineEntry,
} from "./types";

/**
 * Modo demostración (`?demo=1`): datos inventados que se mueven solos, para
 * ensayar o presentar sin backend. La interfaz lo marca siempre.
 */

const hubs: Array<Omit<HubSummary, "fleet"> & { fleet: FleetCounts }> = [
  {
    id: "demo-hub-1",
    name: "Hospital Norte (demo)",
    type: "hospital",
    status: "active",
    latitude: 10.4962,
    longitude: -73.2487,
    fleet: { available: 2, inMission: 1, maintenance: 0, outOfService: 0, total: 3 },
  },
  {
    id: "demo-hub-2",
    name: "Clínica Centro (demo)",
    type: "clinic",
    status: "active",
    latitude: 10.4631,
    longitude: -73.2532,
    fleet: { available: 1, inMission: 1, maintenance: 1, outOfService: 0, total: 3 },
  },
  {
    id: "demo-hub-3",
    name: "Banco de sangre Sur (demo)",
    type: "blood_bank",
    status: "active",
    latitude: 10.4318,
    longitude: -73.2601,
    fleet: { available: 2, inMission: 0, maintenance: 0, outOfService: 0, total: 2 },
  },
];

type Mission = {
  orderId: string;
  droneId: string;
  identifier: string;
  from: number;
  to: number;
  periodMs: number;
  offset: number;
  cold: boolean;
};

const missions: Mission[] = [
  { orderId: "demo-order-1", droneId: "demo-drone-1", identifier: "WG-198-001", from: 0, to: 1, periodMs: 90_000, offset: 0, cold: true },
  { orderId: "demo-order-2", droneId: "demo-drone-2", identifier: "WG-198-004", from: 1, to: 2, periodMs: 120_000, offset: 40_000, cold: false },
];

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

/** Posición y fase de una misión: ida (0 a 1) y regreso (1 a 2). */
function stateAt(mission: Mission, now: number) {
  const p = (((now + mission.offset) % mission.periodMs) / mission.periodMs) * 2;
  const outbound = p < 1;
  const t = outbound ? p : 2 - p;
  const a = hubs[mission.from];
  const b = hubs[mission.to];
  const phase =
    t < 0.06 ? "takeoff" : t < 0.12 ? "transition" : t > 0.94 ? "landing" : t > 0.88 ? "descent" : "cruise";
  return {
    outbound,
    latitude: lerp(a.latitude, b.latitude, t),
    longitude: lerp(a.longitude, b.longitude, t),
    phase,
    battery: Math.max(8, 100 - p * 35),
    eta: Math.round((outbound ? 1 - t : t) * (mission.periodMs / 2000)),
  };
}

function flightOf(mission: Mission, now: number): RadarFlight {
  const s = stateAt(mission, now);
  return {
    orderId: mission.orderId,
    droneId: mission.droneId,
    identifier: mission.identifier,
    hubId: hubs[mission.from].id,
    destinationKind: "hub",
    destinationHubId: hubs[mission.to].id,
    missionType: mission.cold ? "emergency" : "scheduled",
    orderStatus: s.outbound ? "in_flight" : "returning",
    quantity: 4,
    requiresColdChain: mission.cold,
    medicationName: mission.cold ? "Insulina (demo)" : "Suero (demo)",
    phase: s.phase,
    leg: s.outbound ? "outbound" : "return",
    latitude: s.latitude,
    longitude: s.longitude,
    altitudeM: s.phase === "cruise" ? 120 : 40,
    speedKmh: s.phase === "cruise" ? 96 : 35,
    batteryPercent: Math.round(s.battery),
    temperatureC: mission.cold ? 5.1 : null,
    etaSeconds: s.eta,
    alerts: { battery: false, failure: false, coldChain: false },
  };
}

function corridor(mission: Mission, reverse: boolean): Corridor {
  const a = hubs[mission.from];
  const b = hubs[mission.to];
  const points: Array<[number, number]> = [
    [a.longitude, a.latitude],
    [lerp(a.longitude, b.longitude, 0.5) + 0.006, lerp(a.latitude, b.latitude, 0.5)],
    [b.longitude, b.latitude],
  ];
  return {
    altitudeM: 120,
    distanceKm: 6.4,
    coordinates: reverse ? points.reverse() : points,
  };
}

const inventory: InventoryRow[] = [
  { id: "i1", name: "Insulina glargina", quantity: 24, lot: "L-2041", expirationDate: "2027-03-14", requiresColdChain: true, saleType: "prescription" },
  { id: "i2", name: "Suero fisiológico 500 ml", quantity: 120, lot: "L-1187", expirationDate: "2027-08-01", requiresColdChain: false, saleType: "over_the_counter" },
  { id: "i3", name: "Sangre O negativo", quantity: 6, lot: "L-0932", expirationDate: "2026-11-09", requiresColdChain: true, saleType: "special_control" },
];

/** Un paso inventado de la línea de tiempo, en la hora del reloj de demostración. */
function demoEntry(at: string, partial: Partial<TimelineEntry> & Pick<TimelineEntry, "title">): TimelineEntry {
  return {
    id: `demo-${Math.random().toString(36).slice(2)}`,
    at,
    kind: "console",
    severity: "info",
    detail: null,
    orderId: null,
    droneId: null,
    hubId: null,
    latitude: null,
    longitude: null,
    source: "console",
    ...partial,
  };
}

export function demoSource(): RadarSource {
  // La consola de demostración no manda nada al backend: su reloj vive aquí.
  // Arranca la primera vez que se usa (no al prerenderizar la página).
  let clock: ClockView | null = null;
  let anchorReal = 0;
  let listeners: RadarHandlers | null = null;
  const realTime = (): ClockView => {
    anchorReal = Date.now();
    return { now: new Date(anchorReal).toISOString(), speed: 1, paused: false };
  };
  const current = (): ClockView => (clock ??= realTime());
  const nowOf = () => {
    const state = current();
    return state.paused
      ? state.now
      : new Date(Date.parse(state.now) + (Date.now() - anchorReal) * state.speed).toISOString();
  };
  const story = (): TimelineEntry[] => {
    const at = nowOf();
    return [
      demoEntry(at, {
        kind: "flight",
        title: "Carga confirmada: despegó WG-198-001",
        detail: "Desde Hospital Norte (demo), Insulina (demo) hacia Clínica Centro (demo)",
        orderId: "demo-order-1",
        latitude: hubs[0].latitude,
        longitude: hubs[0].longitude,
        source: "system",
      }),
      demoEntry(at, {
        kind: "decision",
        title: "Hospital Norte (demo) autorizó: sale WG-198-001",
        detail: "Eligió WG-198-001. Descartó WG-198-002 (batería insuficiente para ida, regreso y reserva).",
        orderId: "demo-order-1",
        source: "system",
      }),
      demoEntry(at, {
        kind: "queue",
        title: "Urgencia entre centrales en la cola de Hospital Norte (demo)",
        latitude: hubs[0].latitude,
        longitude: hubs[0].longitude,
        source: "system",
      }),
    ];
  };
  return {
    demo: true,
    control: {
      clock: async () => ({ ...current(), now: nowOf() }),
      setClock: async (change) => {
        const previous = current();
        const next: ClockView = {
          now: nowOf(),
          speed: change.speed ?? previous.speed,
          paused: change.paused ?? previous.paused,
        };
        clock = next;
        anchorReal = Date.now();
        listeners?.onClock(next);
        listeners?.onTimeline(
          demoEntry(next.now, {
            title: next.paused ? "Reloj en pausa" : `Reloj a x${next.speed}`,
          }),
        );
        return next;
      },
      timeline: async () => story(),
      alerts: async () => [],
      reset: async () => {
        const fresh = realTime();
        clock = fresh;
        listeners?.onClock(fresh);
        listeners?.onReset();
        listeners?.onTimeline(
          demoEntry(fresh.now, {
            title: "Escenario reiniciado",
            detail: "En modo demostración no se borra nada: es solo un ensayo.",
          }),
        );
        return { orders: 0, drones: 0, inventoryItems: 0, geofences: 0 };
      },
    },
    snapshot: async (): Promise<Snapshot> => ({
      hubs,
      flights: missions.map((m) => flightOf(m, Date.now())),
      geofences: [
        {
          id: "demo-geo-1",
          name: "Zona de eventos (demo)",
          reason: "Evento masivo",
          polygon: {
            type: "Polygon",
            coordinates: [[[-73.262, 10.482], [-73.248, 10.482], [-73.248, 10.472], [-73.262, 10.472], [-73.262, 10.482]]],
          },
        },
      ],
    }),
    hub: async (id): Promise<HubDetail> => {
      const hub = hubs.find((h) => h.id === id) ?? hubs[0];
      const flying = missions.filter((m) => hubs[m.from].id === hub.id);
      return {
        ...hub,
        address: "Dirección de ejemplo (demo)",
        contactPhone: "3000000000",
        contactEmail: "demo@airdrop.test",
        drones: Array.from({ length: hub.fleet.total }, (_, i) => {
          const m = flying[i];
          const status = m
            ? "in_mission"
            : i < hub.fleet.available + flying.length
              ? "available"
              : "maintenance";
          return {
            id: `${hub.id}-d${i}`,
            identifier: m?.identifier ?? `WG-198-0${i + 1}${hubs.indexOf(hub)}`,
            modelName: "Wingcopter 198",
            status,
            maintenanceReason: status === "maintenance" ? "Cambio de hélices" : null,
            flight: m ? flightOf(m, Date.now()) : null,
          } as HubDetail["drones"][number];
        }),
        inventory: { totalUnits: 150, items: inventory, quarantinedUnits: 2 },
        queue: { received: 2, pending_load: 1, in_flight: flying.length },
      };
    },
    flight: async (orderId): Promise<FlightDetail> => {
      const m = missions.find((x) => x.orderId === orderId) ?? missions[0];
      const flight = flightOf(m, Date.now());
      return {
        flight,
        route: corridor(m, false),
        returnRoute: flight.leg === "return" ? corridor(m, true) : null,
        previousRoute: null,
        previousReturnRoute: null,
        originHub: { id: hubs[m.from].id, name: hubs[m.from].name },
        destinationHub: { id: hubs[m.to].id, name: hubs[m.to].name },
      };
    },
    connect(handlers) {
      listeners = handlers;
      handlers.onConnection("live");
      handlers.onClock({ ...current(), now: nowOf() });
      const timer = setInterval(() => {
        const now = Date.now();
        for (const m of missions) {
          const f = flightOf(m, now);
          const event: TelemetryEvent = {
            orderId: f.orderId,
            droneId: f.droneId,
            identifier: f.identifier,
            latitude: f.latitude as number,
            longitude: f.longitude as number,
            altitudeM: f.altitudeM as number,
            speedKmh: f.speedKmh as number,
            phase: f.phase as string,
            leg: f.leg as "outbound" | "return",
            status: f.orderStatus,
            etaSeconds: f.etaSeconds,
            batteryPercent: f.batteryPercent as number,
            temperatureC: f.temperatureC,
          };
          handlers.onTelemetry(event);
        }
      }, 2_000);
      return () => {
        clearInterval(timer);
        listeners = null;
      };
    },
  };
}
