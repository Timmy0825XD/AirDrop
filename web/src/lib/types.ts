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
  /** RF-34: sin enlace, la posición es estimada. Llega por el socket. */
  linkLost?: boolean;
};

export type Geofence = {
  id: string;
  name: string;
  reason: string;
  polygon: { type: "Polygon" | "MultiPolygon"; coordinates: unknown };
  /** RF-36: con fecha, es temporal y vence sola. */
  expiresAt?: string | null;
};

export type Snapshot = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  geofences: Geofence[];
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
export type TimelineEntry = {
  id: string;
  at: string;
  kind: TimelineKind;
  severity: "info" | "success" | "warning" | "danger";
  title: string;
  detail: string | null;
  orderId: string | null;
  droneId: string | null;
  hubId: string | null;
  latitude: number | null;
  longitude: number | null;
  source: "system" | "console";
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

export type WeatherKind = "wind" | "rain" | "storm";

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
