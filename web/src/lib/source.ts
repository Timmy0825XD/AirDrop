import { io } from "socket.io-client";
import { API_URL, api } from "./api";
import type {
  AlertEvent,
  FlightDetail,
  HubDetail,
  Snapshot,
  StatusEvent,
  TelemetryEvent,
} from "./types";

export type Connection = "connecting" | "live" | "reconnecting" | "denied";

export type RadarHandlers = {
  onConnection: (state: Connection, message?: string) => void;
  onTelemetry: (event: TelemetryEvent) => void;
  onStatus: (event: StatusEvent) => void;
  onAlert: (event: AlertEvent) => void;
};

/** De dónde sale el radar: Nest (en vivo) o el simulador de demostración. */
export type RadarSource = {
  demo: boolean;
  snapshot: () => Promise<Snapshot>;
  hub: (id: string) => Promise<HubDetail>;
  flight: (orderId: string) => Promise<FlightDetail>;
  connect: (handlers: RadarHandlers) => () => void;
};

export function liveSource(token: string): RadarSource {
  return {
    demo: false,
    snapshot: () => api<Snapshot>("/radar/snapshot", token),
    hub: (id) => api<HubDetail>(`/radar/hubs/${id}`, token),
    flight: (orderId) => api<FlightDetail>(`/radar/flights/${orderId}`, token),
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
      return () => {
        socket.removeAllListeners();
        socket.disconnect();
      };
    },
  };
}
