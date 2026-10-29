import type { RadarSource } from "./source";
import type {
  Corridor,
  FleetCounts,
  FlightDetail,
  HubDetail,
  HubSummary,
  InventoryRow,
  RadarFlight,
  Snapshot,
  TelemetryEvent,
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

export function demoSource(): RadarSource {
  return {
    demo: true,
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
        originHub: { id: hubs[m.from].id, name: hubs[m.from].name },
        destinationHub: { id: hubs[m.to].id, name: hubs[m.to].name },
      };
    },
    connect(handlers) {
      handlers.onConnection("live");
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
      return () => clearInterval(timer);
    },
  };
}
