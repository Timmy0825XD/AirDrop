/** Contrato de `GET /radar/*` y del socket `/telemetry` (ver backend/src/radar). */

export type FleetCounts = {
  available: number;
  inMission: number;
  maintenance: number;
  /** RF-34: aterrizó de emergencia y espera el rescate. */
  grounded?: number;
  outOfService: number;
  total: number;
};

export type HubSummary = {
  id: string;
  name: string;
  type: string;
  /** RF-06: solo un nodo tiene drones; una ESE recibe traslados. */
  networkRole?: HubNetworkRole;
  status: "active" | "suspended" | string;
  latitude: number;
  longitude: number;
  fleet: FleetCounts;
  /** RF-36: sin energía hasta esta hora simulada (ISO), o `null`. */
  powerOutageUntil?: string | null;
  /** B10: pedidos que esperan su autorización o su carga. */
  queue?: number;
};

export type RadarFlight = {
  orderId: string;
  droneId: string;
  identifier: string;
  hubId: string;
  destinationKind: "person" | "hub";
  destinationHubId: string | null;
  missionType: "emergency" | "scheduled";
  orderStatus: string;
  quantity: number;
  requiresColdChain: boolean;
  medicationName: string | null;
  phase: string | null;
  leg: "outbound" | "return" | null;
  latitude: number | null;
  longitude: number | null;
  altitudeM: number | null;
  speedKmh: number | null;
  batteryPercent: number | null;
  temperatureC: number | null;
  etaSeconds: number | null;
  alerts: { battery: boolean; failure: boolean; coldChain: boolean };
  /** RF-34: sin enlace, la posición es estimada. */
  linkLost?: boolean;
  /** RF-46: metros sobre el nivel del mar; `null` sin perfil de terreno. */
  altitudeMslM?: number | null;
  /** RF-48: la identificación remota de la última lectura. */
  remoteId?: RemoteId | null;
};

export type RemoteIdStatus = "mission" | "returning" | "link_lost" | "emergency";

/** RF-48: lo que el dron anuncia de sí mismo. */
export type RemoteId = {
  /** "AD-NOR-01" */
  registration: string;
  operator: string;
  /** "Colibrí", "Garza" o "Cóndor". */
  type: string;
  /** `null` de regreso vacío. */
  manifestNumber: string | null;
  status: RemoteIdStatus;
};

/** RF-47: el manifiesto en `GET /radar/flights/:orderId`. */
export type RadarManifest = {
  id: string;
  number: string;
  orderId: string;
  issuedAt: string;
  drone: { id: string; identifier: string; kind: "rapid" | "balanced" | "cargo" };
  origin: { hubId: string; name: string };
  /** El punto de entrega o la ESE. */
  destination: string;
  /** `medicationName` llega `null` en una entrega a una persona. */
  items: Array<{
    medicationName: string | null;
    lot: string;
    expiresOn: string;
    quantity: number;
  }>;
  payloadKg: number;
  coldCompartmentKg: number | null;
  coldRange: string | null;
  authorizedBy: { userId: string | null; name: string };
  voidedAt: string | null;
  voidReason: string | null;
};

/** RF-44: `GET /airspace/daylight`, con la hora simulada. */
export type Daylight = {
  date: string;
  sunrise: string;
  sunset: string;
  now: string;
  daylight: boolean;
};

export type Geofence = {
  id: string;
  name: string;
  reason: string;
  polygon: { type: "Polygon" | "MultiPolygon"; coordinates: unknown };
  /** RF-36: con fecha, es temporal y vence sola. */
  expiresAt?: string | null;
};

export type HubNetworkRole = "node" | "ese";

/** RF-43 a escala de demo: aeródromo (1,5 km), prohibida y helipuerto. */
export type AirspaceZoneKind = "aerodrome" | "prohibited" | "heliport";

/** RF-43: una zona legal de la región (`snapshot.airspace`, `GET /airspace/zones`). */
export type AirspaceZone = {
  code: string;
  kind: AirspaceZoneKind;
  name: string;
  /** La norma: "RAC 100.315(a)(14): 1,5 km desde el ARP (demo…)". */
  legalBasis: string;
  source: string;
  /** Todas bloquean en la demo. */
  blocking: boolean;
  polygon: { type: "Polygon"; coordinates: number[][][] };
};

/** RF-45: un punto de entrega (`GET /delivery-points`). */
export type DeliveryPoint = {
  id: string;
  code: string;
  name: string;
  municipality: string;
  latitude: number;
  longitude: number;
  elevationM: number;
  /** El nodo que lo atiende. */
  hubId: string | null;
  active: boolean;
  /** Activo y con su nodo activo. */
  available: boolean;
};

export type Snapshot = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  geofences: Geofence[];
  /** RF-43: las zonas legales. No cambian en ejecución. */
  airspace?: AirspaceZone[];
};

export type HubDrone = {
  id: string;
  identifier: string;
  modelName: string | null;
  status: "available" | "in_mission" | "maintenance" | "grounded" | "out_of_service";
  maintenanceReason: string | null;
  flight: RadarFlight | null;
};

export type InventoryRow = {
  id: string;
  name: string;
  quantity: number;
  lot: string;
  expirationDate: string;
  requiresColdChain: boolean;
  saleType: string;
};

export type HubDetail = {
  id: string;
  name: string;
  type: string;
  status: string;
  address: string;
  latitude: number;
  longitude: number;
  contactPhone: string;
  contactEmail: string | null;
  fleet: FleetCounts;
  drones: HubDrone[];
  inventory: {
    totalUnits: number;
    items: InventoryRow[];
    quarantinedUnits: number;
  };
  queue: Record<string, number>;
};

export type Corridor = {
  altitudeM: number;
  distanceKm: number;
  coordinates: Array<[number, number]>;
};

export type FlightDetail = {
  flight: RadarFlight | null;
  route: Corridor | null;
  returnRoute: Corridor | null;
  /** RF-33: lo que iba a volar antes de cambiar la ruta en el aire. */
  previousRoute: Array<[number, number]> | null;
  previousReturnRoute: Array<[number, number]> | null;
  originHub: { id: string; name: string } | null;
  destinationHub: { id: string; name: string } | null;
  /** RF-47: el manifiesto vigente; `null` si todavía no hay. */
  manifest?: RadarManifest | null;
};

/** Evento `radar-telemetry` (vista `full` de la telemetría). */
export type TelemetryEvent = {
  orderId: string;
  droneId: string;
  identifier: string;
  latitude: number;
  longitude: number;
  altitudeM: number;
  speedKmh: number;
  phase: string;
  leg: "outbound" | "return";
  status: string;
  etaSeconds: number | null;
  batteryPercent: number;
  temperatureC: number | null;
  linkLost?: boolean;
  altitudeMslM?: number | null;
  remoteId?: RemoteId | null;
};

export type StatusEvent = { orderId: string; status: string };

export type AlertEvent = {
  orderId: string;
  droneId: string;
  kind: "battery_critical" | "failure" | "cold_chain" | "wind_limit";
  message: string;
};

export type Selection =
  | { kind: "hub"; id: string }
  | { kind: "flight"; id: string }
  /** Una celda de clima o una geovalla temporal (RF-32, RF-36). */
  | { kind: "weather"; id: string }
  | { kind: "zone"; id: string }
  /** Una zona legal (RF-43) o un punto de entrega (RF-45). */
  | { kind: "airspace"; id: string }
  | { kind: "point"; id: string }
  /** Un dron no identificado (RF-36). */
  | { kind: "contact"; id: string }
  | null;

/* Consola de simulación (`/control/*` y el socket). Ver backend/src/control. */

export type ClockSpeed = 1 | 2 | 4 | 8;

/** Evento `clock` y `GET /control/clock` (RF-31). */
export type ClockView = { now: string; speed: ClockSpeed; paused: boolean };

export type TimelineKind =
  | "order"
  | "queue"
  | "decision"
  | "flight"
  | "delivery"
  | "fallback"
  | "alert"
  | "console";

/** Evento `radar-timeline` y `GET /control/timeline` (RF-39). */
export type TimelineCategory =
  | "order"
  | "flight"
  | "incident"
  | "environment"
  | "console";

export type TimelineSection = { title: string; lines: string[] };

export type TimelineEntry = {
  id: string;
  at: string;
  kind: TimelineKind;
  severity: "info" | "success" | "warning" | "danger";
  title: string;
  detail: string | null;
  /** Para los filtros; `console` es lo técnico y se oculta por defecto. */
  category?: TimelineCategory;
  /** Por qué decidió el sistema: "Por qué este nodo", "Por qué este dron". */
  explanation?: TimelineSection[] | null;
  orderId: string | null;
  droneId: string | null;
  hubId: string | null;
  latitude: number | null;
  longitude: number | null;
  /** `chaos`: lo sorteó el modo caos (RF-38). */
  source: "system" | "console" | "chaos";
};

/** `GET /control/alerts`: alertas de vuelo abiertas (RF-39). */
export type PendingAlert = {
  orderId: string;
  droneId: string;
  identifier: string;
  hubId: string;
  /** `emergency_landing`: el dron espera el rescate fuera de su central (RF-34). */
  kinds: Array<AlertEvent["kind"] | "emergency_landing">;
  latitude: number | null;
  longitude: number | null;
};

/** `POST /control/reset` (RF-40). */
export type ResetSummary = {
  orders: number;
  drones: number;
  inventoryItems: number;
  geofences: number;
};

/* Eventos de la consola (CU-38): clima, geovallas temporales, incidentes y apagones. */

/** RF-32: la niebla es zona no volable, como la tormenta. */
export type WeatherKind = "wind" | "rain" | "storm" | "fog";

/** `GET /control/weather` y `radar-weather` (RF-32). */
export type WeatherCell = {
  id: string;
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  windSpeedMs: number | null;
  windGustMs: number | null;
  windFromDeg: number | null;
  startsAt: string;
  endsAt: string;
};

/** Cuerpo de `POST /control/weather`. */
export type NewWeather = {
  kind: WeatherKind;
  latitude: number;
  longitude: number;
  radiusKm: number;
  durationMin: number;
  windSpeedMs?: number;
  windGustMs?: number;
  windFromDeg?: number;
};

/** `GET /control/geofences` y `radar-geofence` (RF-36). */
export type TemporaryZone = {
  id: string;
  name: string;
  reason: string;
  polygon: { type: "Polygon"; coordinates: number[][][] };
  createdAt: string;
  expiresAt: string;
};

export type NewZone = {
  name: string;
  reason: string;
  polygon: { type: "Polygon"; coordinates: number[][][] };
  durationMin: number;
};

/** El catálogo que la consola lanza sobre un dron en vuelo (RF-34). */
export type ConsoleIncidentKind =
  | "battery_degraded"
  | "motor_failure"
  | "dual_motor_failure"
  | "gps_loss_minor"
  | "gps_loss_major"
  | "link_loss"
  | "cooling_failure"
  | "collision_minor"
  | "collision_major"
  | "drone_lost";

export type IncidentKind =
  | ConsoleIncidentKind
  | "battery_critical"
  | "wind_limit"
  | "route_blocked"
  | "battery_short";

export type IncidentProtocol =
  | "continue"
  | "return_to_hub"
  | "emergency_landing"
  | "crash"
  | "lost";

export type IncidentOutcome =
  | "continued"
  | "returning"
  | "returned"
  | "landing"
  | "grounded"
  | "rescued"
  | "lost";

/** `GET /control/incidents` y `radar-incident` (RF-34). */
export type Incident = {
  id: string;
  orderId: string;
  droneId: string;
  hubId: string;
  kind: IncidentKind;
  severity: "minor" | "major";
  leg: "outbound" | "return";
  protocol: IncidentProtocol;
  outcome: IncidentOutcome;
  latitude: number;
  longitude: number;
  batteryPercent: number;
  landingLatitude: number | null;
  landingLongitude: number | null;
  rescueDueAt: string | null;
  packageOnBoard: boolean;
  packageLost: boolean;
  occurredAt: string;
  resolvedAt: string | null;
};

/** `GET /control/hubs/outages` y `radar-hub-outage` (RF-36). */
export type HubOutage = {
  hubId: string;
  name: string;
  latitude: number;
  longitude: number;
  until: string;
};

/** RF-37: los actores simulados encendidos. Arrancan apagados. */
export type ActorsState = {
  /** Autoriza y confirma la carga en cualquier central activa. */
  autoDispatcher: boolean;
  /** Un pedido de un solicitante simulado cada 3 min simulados. */
  orderFlow: boolean;
};

export type GeneratedKind = "emergency" | "scheduled";

/** CU-39: lo que creó el generador. Sin datos de personas: el solicitante es simulado. */
export type GeneratedOrder = {
  kind: GeneratedKind;
  orderId: string | null;
  planId: string | null;
  address: string;
  latitude: number;
  longitude: number;
  /** RF-45: el punto de entrega al que va. */
  deliveryPointId?: string;
};

/** RF-36 y RF-48: un dron sin identificación que cruza la región. */
export type UnidentifiedContact = {
  id: string;
  latitude: number;
  longitude: number;
  from: { latitude: number; longitude: number };
  to: { latitude: number; longitude: number };
  speedKmh: number;
  /** Hora simulada. */
  startedAt: string;
  endsAt: string;
  /** La matrícula del dron propio a menos de 1 km, si hay. */
  nearIdentifier: string | null;
};

/** Evento `radar-unidentified`. */
export type UnidentifiedEvent = {
  action: "started" | "moved" | "ended";
  contact: UnidentifiedContact;
};

/** RF-36: pico de urgencias dentro de un círculo del mapa. */
export type NewSurge = {
  latitude: number;
  longitude: number;
  radiusKm: number;
  count: number;
};

export type SurgeResult = {
  requested: number;
  created: GeneratedOrder[];
  /** Por qué no salieron las que faltan, tal como lo dijo Nest. */
  failures: string[];
};

/** RF-38: el modo caos. Arranca apagado. */
export type ChaosIntensity = "low" | "medium" | "high";

export type ChaosState = {
  enabled: boolean;
  intensity: ChaosIntensity;
};
