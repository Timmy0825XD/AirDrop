/** Contrato de `GET /radar/*` y del socket `/telemetry` (ver backend/src/radar). */

export type FleetCounts = {
  available: number;
  inMission: number;
  maintenance: number;
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
};

export type Geofence = {
  id: string;
  name: string;
  reason: string;
  polygon: { type: "Polygon" | "MultiPolygon"; coordinates: unknown };
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
  status: "available" | "in_mission" | "maintenance" | "out_of_service";
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
};

export type StatusEvent = { orderId: string; status: string };

export type AlertEvent = {
  orderId: string;
  droneId: string;
  kind: "battery_critical" | "failure" | "cold_chain";
  message: string;
};

export type Selection =
  | { kind: "hub"; id: string }
  | { kind: "flight"; id: string }
  | null;
