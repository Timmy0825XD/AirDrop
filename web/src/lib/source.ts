import { io } from "socket.io-client";
import { API_URL, api } from "./api";
import type {
  AlertEvent,
  ClockSpeed,
  ClockView,
  FlightDetail,
  HubDetail,
  PendingAlert,
  ResetSummary,
  Snapshot,
  StatusEvent,
  TelemetryEvent,
  TimelineEntry,
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
};

export type ClockChange = { speed?: ClockSpeed; paused?: boolean };

/** Órdenes de la consola de simulación (`/control/*`, solo admin). */
export type ConsoleApi = {
  clock: () => Promise<ClockView>;
  setClock: (change: ClockChange) => Promise<ClockView>;
  timeline: (limit: number) => Promise<TimelineEntry[]>;
  alerts: () => Promise<PendingAlert[]>;
  reset: () => Promise<ResetSummary>;
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
      return () => {
        socket.removeAllListeners();
        socket.disconnect();
      };
    },
  };
}
