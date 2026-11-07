import { io } from "socket.io-client";
import { API_URL, api } from "./api";
import type {
  AlertEvent,
  ClockSpeed,
  ClockView,
  ConsoleIncidentKind,
  FlightDetail,
  HubDetail,
  HubOutage,
  Incident,
  NewWeather,
  NewZone,
  PendingAlert,
  ResetSummary,
  Snapshot,
  StatusEvent,
  TelemetryEvent,
  TemporaryZone,
  TimelineEntry,
  WeatherCell,
} from "./types";

export type Connection = "connecting" | "live" | "reconnecting" | "denied";

export type RadarHandlers = {
  onConnection: (state: Connection, message?: string) => void;
  onTelemetry: (event: TelemetryEvent) => void;
  onStatus: (event: StatusEvent) => void;
  onAlert: (event: AlertEvent) => void;
  /** RF-31: cambió la velocidad o la pausa (y llega al conectar). */
  onClock: (clock: ClockView) => void;
  /** RF-39: un paso nuevo del flujo. */
  onTimeline: (entry: TimelineEntry) => void;
  /** RF-40: el escenario volvió a la semilla. */
  onReset: () => void;
  /**
   * CU-38: cambió el mundo de la consola (clima, geovalla temporal,
   * incidente, apagón o una ruta en el aire). Se vuelven a leer las capas.
   */
  onWorld: (what: WorldChange) => void;
};

export type WorldChange = "weather" | "zone" | "incident" | "outage" | "reroute";

export type ClockChange = { speed?: ClockSpeed; paused?: boolean };

/** Órdenes de la consola de simulación (`/control/*`, solo admin). */
export type ConsoleApi = {
  clock: () => Promise<ClockView>;
  setClock: (change: ClockChange) => Promise<ClockView>;
  timeline: (limit: number) => Promise<TimelineEntry[]>;
  alerts: () => Promise<PendingAlert[]>;
  reset: () => Promise<ResetSummary>;
  /* CU-38: los eventos que se lanzan sobre el mapa. */
  weather: () => Promise<WeatherCell[]>;
  createWeather: (input: NewWeather) => Promise<WeatherCell>;
  endWeather: (id: string) => Promise<WeatherCell>;
  zones: () => Promise<TemporaryZone[]>;
  createZone: (input: NewZone) => Promise<TemporaryZone>;
  endZone: (id: string) => Promise<TemporaryZone>;
  incidents: (limit: number) => Promise<Incident[]>;
  launchIncident: (droneId: string, kind: ConsoleIncidentKind) => Promise<Incident>;
  outages: () => Promise<HubOutage[]>;
  startOutage: (hubId: string, durationMin: number) => Promise<HubOutage>;
  endOutage: (hubId: string) => Promise<HubOutage>;
};

/** De dónde sale el radar: Nest (en vivo) o el simulador de demostración. */
export type RadarSource = {
  demo: boolean;
  snapshot: () => Promise<Snapshot>;
  hub: (id: string) => Promise<HubDetail>;
  flight: (orderId: string) => Promise<FlightDetail>;
  control: ConsoleApi;
  connect: (handlers: RadarHandlers) => () => void;
};

export function liveSource(token: string): RadarSource {
  return {
    demo: false,
    snapshot: () => api<Snapshot>("/radar/snapshot", token),
    hub: (id) => api<HubDetail>(`/radar/hubs/${id}`, token),
    flight: (orderId) => api<FlightDetail>(`/radar/flights/${orderId}`, token),
    control: {
      clock: () => api<ClockView>("/control/clock", token),
      setClock: (change) =>
        api<ClockView>("/control/clock", token, {
          method: "PUT",
          body: JSON.stringify(change),
        }),
      timeline: (limit) => api<TimelineEntry[]>(`/control/timeline?limit=${limit}`, token),
      alerts: () => api<PendingAlert[]>("/control/alerts", token),
      reset: () => api<ResetSummary>("/control/reset", token, { method: "POST" }),
      weather: () => api<WeatherCell[]>("/control/weather", token),
      createWeather: (input) =>
        api<WeatherCell>("/control/weather", token, {
          method: "POST",
          body: JSON.stringify(input),
        }),
      endWeather: (id) => api<WeatherCell>(`/control/weather/${id}`, token, { method: "DELETE" }),
      zones: () => api<TemporaryZone[]>("/control/geofences", token),
      createZone: (input) =>
        api<TemporaryZone>("/control/geofences", token, {
          method: "POST",
          body: JSON.stringify(input),
        }),
      endZone: (id) => api<TemporaryZone>(`/control/geofences/${id}`, token, { method: "DELETE" }),
      incidents: (limit) => api<Incident[]>(`/control/incidents?limit=${limit}`, token),
      launchIncident: (droneId, kind) =>
        api<Incident>(`/control/drones/${droneId}/incidents`, token, {
          method: "POST",
          body: JSON.stringify({ kind }),
        }),
      outages: () => api<HubOutage[]>("/control/hubs/outages", token),
      startOutage: (hubId, durationMin) =>
        api<HubOutage>(`/control/hubs/${hubId}/outage`, token, {
          method: "POST",
          body: JSON.stringify({ durationMin }),
        }),
      endOutage: (hubId) =>
        api<HubOutage>(`/control/hubs/${hubId}/outage`, token, { method: "DELETE" }),
    },
    connect(handlers) {
      const socket = io(`${API_URL}/telemetry`, {
        auth: { token },
        transports: ["websocket"],
        reconnectionDelayMax: 5_000,
      });
      // Cada conexión (también las reconexiones) vuelve a pedir la sala.
      socket.on("connect", () => socket.emit("subscribe-radar"));
      socket.on("subscribed-radar", () => handlers.onConnection("live"));
      socket.on("error", (body: { message?: string }) =>
        handlers.onConnection("denied", body?.message),
      );
      socket.on("connect_error", () => handlers.onConnection("reconnecting"));
      socket.on("disconnect", () => handlers.onConnection("reconnecting"));
      socket.on("radar-telemetry", handlers.onTelemetry);
      socket.on("radar-status", handlers.onStatus);
      socket.on("radar-alert", handlers.onAlert);
      socket.on("clock", handlers.onClock);
      socket.on("radar-timeline", handlers.onTimeline);
      socket.on("radar-reset", handlers.onReset);
      socket.on("radar-weather", () => handlers.onWorld("weather"));
      socket.on("radar-geofence", () => handlers.onWorld("zone"));
      socket.on("radar-incident", () => handlers.onWorld("incident"));
      socket.on("radar-hub-outage", () => handlers.onWorld("outage"));
      socket.on("radar-reroute", () => handlers.onWorld("reroute"));
      return () => {
        socket.removeAllListeners();
        socket.disconnect();
      };
    },
  };
}
