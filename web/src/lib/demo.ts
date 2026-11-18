import { circlePolygon } from "./geo";
import type { RadarHandlers, RadarSource } from "./source";
import type {
  ActorsState,
  AirspaceZone,
  ChaosState,
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
  TemporaryZone,
  TimelineEntry,
  UnidentifiedContact,
  WeatherCell,
} from "./types";

/** Incidentes, apagones y pedidos generados mueven pedidos de verdad: en el ensayo no aplican. */
const DEMO_ONLY_REAL =
  "En modo demostración no se lanzan incidentes, apagones ni pedidos: necesitan el backend.";

/**
 * Modo demostración (`?demo=1`): datos inventados que se mueven solos, para
 * ensayar o presentar sin backend. La interfaz lo marca siempre.
 */

/** La red regional de la demostración: las coordenadas de `regional-network.ts`. */
const hubs: Array<Omit<HubSummary, "fleet"> & { fleet: FleetCounts }> = [
  {
    id: "demo-node-north",
    name: "Central Norte (demo)",
    type: "clinic",
    status: "active",
    latitude: 10.6075,
    longitude: -73.2237,
    fleet: { available: 2, inMission: 0, maintenance: 0, outOfService: 0, total: 2 },
  },
  {
    id: "demo-node-south",
    name: "Central Sur (demo)",
    type: "clinic",
    status: "active",
    latitude: 10.355,
    longitude: -73.14,
    fleet: { available: 1, inMission: 1, maintenance: 1, outOfService: 0, total: 3 },
  },
  {
    id: "demo-node-codazzi",
    name: "Central Codazzi (demo)",
    type: "clinic",
    status: "active",
    latitude: 10.055,
    longitude: -73.255,
    fleet: { available: 1, inMission: 1, maintenance: 0, outOfService: 0, total: 2 },
  },
  {
    id: "demo-ese-la-paz",
    name: "ESE Hospital de La Paz (demo)",
    type: "hospital",
    status: "active",
    latitude: 10.3844,
    longitude: -73.1733,
    fleet: { available: 1, inMission: 0, maintenance: 0, outOfService: 0, total: 1 },
  },
  {
    id: "demo-ese-codazzi",
    name: "ESE Hospital de Codazzi (demo)",
    type: "hospital",
    status: "active",
    latitude: 10.0367,
    longitude: -73.2356,
    fleet: { available: 1, inMission: 0, maintenance: 0, outOfService: 0, total: 1 },
  },
];

/** RF-43 a escala de demo: el anillo del aeropuerto y dos CAI de Valledupar. */
const airspace: AirspaceZone[] = [
  {
    code: "demo-skvp",
    kind: "aerodrome",
    name: "Aeropuerto Alfonso López (demo)",
    legalBasis: "RAC 100.315(a)(14): 1,5 km desde el ARP (demo; la norma pide 9 km)",
    source: "Datos de demostración",
    blocking: true,
    polygon: circlePolygon(10.43513, -73.2494, 1.5, 32),
  },
  {
    code: "demo-cai-gobernacion",
    kind: "prohibited",
    name: "CAI Gobernación (demo)",
    legalBasis: "RAC 100.315(a)(13): tamaño del visor de la Aerocivil (demo)",
    source: "Datos de demostración",
    blocking: true,
    polygon: circlePolygon(10.4705, -73.2494, 0.1, 12),
  },
  {
    code: "demo-cai-mayales",
    kind: "prohibited",
    name: "CAI Mayales (demo)",
    legalBasis: "RAC 100.315(a)(13): tamaño del visor de la Aerocivil (demo)",
    source: "Datos de demostración",
    blocking: true,
    polygon: circlePolygon(10.4535, -73.2428, 0.1, 12),
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
  // Una central le manda a la ESE de su zona.
  { orderId: "demo-order-1", droneId: "demo-drone-1", identifier: "AD-SUR-01", from: 1, to: 3, periodMs: 90_000, offset: 0, cold: true },
  { orderId: "demo-order-2", droneId: "demo-drone-2", identifier: "AD-COD-01", from: 2, to: 4, periodMs: 120_000, offset: 40_000, cold: false },
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
    altitudeM: s.phase === "cruise" ? 90 : 40,
    speedKmh: s.phase === "cruise" ? 96 : 35,
    batteryPercent: Math.round(s.battery),
    temperatureC: mission.cold ? 5.1 : null,
    etaSeconds: s.eta,
    alerts: { battery: false, failure: false, coldChain: false },
    altitudeMslM: (s.phase === "cruise" ? 90 : 40) + 160,
    remoteId: {
      registration: mission.identifier,
      operator: "AirDrop (demo)",
      type: mission.cold ? "Colibrí" : "Garza",
      manifestNumber: s.outbound ? `MAN-2026-00000${mission.cold ? 1 : 2}` : null,
      status: s.outbound ? "mission" : "returning",
    },
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
    altitudeM: 90,
    distanceKm: 4.8,
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
        title: "Carga confirmada: despegó AD-SUR-01",
        detail: "Desde Central Sur (demo), Insulina (demo) hacia ESE Hospital de La Paz (demo)",
        orderId: "demo-order-1",
        latitude: hubs[1].latitude,
        longitude: hubs[1].longitude,
        source: "system",
      }),
      demoEntry(at, {
        kind: "decision",
        title: "Central Sur (demo) autorizó: sale AD-SUR-01",
        detail: "Eligió AD-SUR-01. Descartó AD-SUR-02 (batería insuficiente para ida, regreso y reserva).",
        orderId: "demo-order-1",
        source: "system",
      }),
      demoEntry(at, {
        kind: "queue",
        title: "Urgencia entre centrales en la cola de Central Sur (demo)",
        latitude: hubs[1].latitude,
        longitude: hubs[1].longitude,
        source: "system",
      }),
    ];
  };
  /** Lo que se ensaya en este navegador; se pierde al recargar. */
  const cells: WeatherCell[] = [];
  const zones: TemporaryZone[] = [];
  // RF-36: el contacto se ensaya quieto, cruzando el corredor de la primera misión.
  const contacts: UnidentifiedContact[] = [];
  // RF-37: los interruptores se ensayan aquí; no hay actores que corran.
  let actors: ActorsState = { autoDispatcher: false, orderFlow: false };
  // RF-38: el interruptor se ensaya; en el ensayo no se sortea nada.
  let chaos: ChaosState = { enabled: false, intensity: "medium" };
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
      // Clima y zonas temporales se ensayan solo en este navegador.
      weather: async () => cells.filter((cell) => Date.parse(cell.endsAt) > Date.now()),
      createWeather: async (input) => {
        const now = Date.now();
        const cell: WeatherCell = {
          id: `demo-weather-${now}`,
          kind: input.kind,
          latitude: input.latitude,
          longitude: input.longitude,
          radiusKm: input.radiusKm,
          windSpeedMs: input.windSpeedMs ?? null,
          windGustMs: input.windGustMs ?? null,
          windFromDeg: input.windFromDeg ?? null,
          startsAt: new Date(now).toISOString(),
          endsAt: new Date(now + input.durationMin * 60_000).toISOString(),
        };
        cells.push(cell);
        listeners?.onWorld("weather");
        return cell;
      },
      endWeather: async (id) => {
        const cell = cells.find((row) => row.id === id);
        if (!cell) throw new Error("Esa celda de clima no existe.");
        cells.splice(cells.indexOf(cell), 1);
        listeners?.onWorld("weather");
        return cell;
      },
      zones: async () => zones.filter((zone) => Date.parse(zone.expiresAt) > Date.now()),
      createZone: async (input) => {
        const now = Date.now();
        const zone: TemporaryZone = {
          id: `demo-zone-${now}`,
          name: input.name,
          reason: input.reason,
          polygon: input.polygon,
          createdAt: new Date(now).toISOString(),
          expiresAt: new Date(now + input.durationMin * 60_000).toISOString(),
        };
        zones.push(zone);
        listeners?.onWorld("zone");
        return zone;
      },
      endZone: async (id) => {
        const zone = zones.find((row) => row.id === id);
        if (!zone) throw new Error("Esa geovalla temporal no existe o ya venció.");
        zones.splice(zones.indexOf(zone), 1);
        listeners?.onWorld("zone");
        return zone;
      },
      incidents: async () => [],
      launchIncident: async () => {
        throw new Error(DEMO_ONLY_REAL);
      },
      outages: async () => [],
      startOutage: async () => {
        throw new Error(DEMO_ONLY_REAL);
      },
      endOutage: async () => {
        throw new Error(DEMO_ONLY_REAL);
      },
      actors: async () => ({ ...actors }),
      setActors: async (change) => {
        actors = { ...actors, ...change };
        listeners?.onActors({ ...actors });
        listeners?.onTimeline(
          demoEntry(nowOf(), {
            title: change.autoDispatcher !== undefined
              ? `Despachador automático ${actors.autoDispatcher ? "encendido" : "apagado"} (demo)`
              : `Flujo continuo de pedidos ${actors.orderFlow ? "encendido" : "apagado"} (demo)`,
          }),
        );
        return { ...actors };
      },
      unidentified: async () => contacts.filter((row) => Date.parse(row.endsAt) > Date.now()),
      launchUnidentified: async (durationMin) => {
        const now = Date.now();
        const mission = missions[0];
        const a = hubs[mission.from];
        const b = hubs[mission.to];
        const contact: UnidentifiedContact = {
          id: `demo-contact-${now}`,
          latitude: lerp(a.latitude, b.latitude, 0.5),
          longitude: lerp(a.longitude, b.longitude, 0.5),
          from: { latitude: a.latitude + 0.03, longitude: a.longitude - 0.04 },
          to: { latitude: b.latitude - 0.03, longitude: b.longitude + 0.04 },
          speedKmh: 45,
          startedAt: new Date(now).toISOString(),
          endsAt: new Date(now + durationMin * 60_000).toISOString(),
          nearIdentifier: mission.identifier,
        };
        contacts.push(contact);
        listeners?.onUnidentified({ action: "started", contact });
        listeners?.onTimeline(
          demoEntry(nowOf(), {
            kind: "alert",
            severity: "danger",
            title: "Dron no identificado cerca de un corredor (demo)",
            latitude: contact.latitude,
            longitude: contact.longitude,
          }),
        );
        return contact;
      },
      chaos: async () => ({ ...chaos }),
      setChaos: async (change) => {
        chaos = { ...chaos, ...change };
        listeners?.onChaos({ ...chaos });
        listeners?.onTimeline(
          demoEntry(nowOf(), {
            title: chaos.enabled ? "Modo caos encendido (demo: no sortea)" : "Modo caos apagado (demo)",
          }),
        );
        return { ...chaos };
      },
      generateOrder: async () => {
        throw new Error(DEMO_ONLY_REAL);
      },
      surge: async () => {
        throw new Error(DEMO_ONLY_REAL);
      },
      reset: async () => {
        const fresh = realTime();
        clock = fresh;
        actors = { autoDispatcher: false, orderFlow: false };
        listeners?.onActors({ ...actors });
        chaos = { enabled: false, intensity: "medium" };
        listeners?.onChaos({ ...chaos });
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
        ...zones
          .filter((zone) => Date.parse(zone.expiresAt) > Date.now())
          .map((zone) => ({ ...zone })),
        {
          id: "demo-geo-1",
          name: "Zona de eventos (demo)",
          reason: "Evento masivo",
          polygon: circlePolygon(10.3, -73.16, 1.5, 16),
        },
      ],
      airspace,
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
            identifier: m?.identifier ?? `AD-DEMO-${hubs.indexOf(hub)}${i + 1}`,
            modelName: i % 2 ? "Colibrí" : "Garza",
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
        manifest:
          flight.leg === "outbound"
            ? {
                id: `demo-manifest-${m.orderId}`,
                number: flight.remoteId?.manifestNumber ?? "MAN-2026-000001",
                orderId: m.orderId,
                issuedAt: nowOf(),
                drone: { id: m.droneId, identifier: m.identifier, kind: m.cold ? "rapid" : "balanced" },
                origin: { hubId: hubs[m.from].id, name: hubs[m.from].name },
                destination: hubs[m.to].name,
                items: [
                  {
                    medicationName: flight.medicationName,
                    lot: m.cold ? "L-2041" : "L-1187",
                    expiresOn: m.cold ? "2027-03-14" : "2027-08-01",
                    quantity: flight.quantity,
                  },
                ],
                payloadKg: m.cold ? 0.24 : 2.1,
                coldCompartmentKg: m.cold ? 1 : null,
                coldRange: m.cold ? "2–8 °C" : null,
                authorizedBy: { userId: null, name: "Despachador automático (demo)" },
                voidedAt: null,
                voidReason: null,
              }
            : null,
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
            altitudeMslM: f.altitudeMslM,
            remoteId: f.remoteId,
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
