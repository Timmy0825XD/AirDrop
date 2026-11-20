"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ApiError } from "./api";
import type { ReceivedClock } from "./sim-time";
import type { Connection, RadarSource, WorldChange } from "./source";
import type {
  ActorsState,
  AirspaceZone,
  AlertEvent,
  ChaosState,
  Geofence,
  HubSummary,
  RadarFlight,
  Snapshot,
  TelemetryEvent,
  TimelineEntry,
  UnidentifiedEvent,
} from "./types";

/** Cada cuánto se agrupan los mensajes del socket antes de repintar. */
const FLUSH_MS = 250;
/** Red de seguridad por si se pierde algún evento de estado. */
const REFRESH_MS = 30_000;

export type RadarData = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  geofences: Geofence[];
  /** RF-43: las zonas legales de la región. */
  airspace: AirspaceZone[];
  connection: Connection;
  message: string | null;
  loaded: boolean;
  /** RF-31: la última hora simulada que mandó el backend. */
  clock: ReceivedClock | null;
};

/** Lo que la consola escucha del mismo socket (un solo canal en tiempo real). */
export type ConsoleListener = {
  onTimeline: (entry: TimelineEntry) => void;
  onReset: () => void;
  /** CU-38: clima, zona, incidente, apagón o ruta cambiaron. */
  onWorld: (what: WorldChange) => void;
  /** RF-37: cambiaron los interruptores de los actores. */
  onActors: (actors: ActorsState) => void;
  /** RF-38: cambió el modo caos. */
  onChaos: (chaos: ChaosState) => void;
  /** RF-36: un dron no identificado apareció, se movió o salió. */
  onUnidentified: (event: UnidentifiedEvent) => void;
};

function fromTelemetry(event: TelemetryEvent, previous?: RadarFlight): RadarFlight {
  return {
    orderId: event.orderId,
    droneId: event.droneId,
    identifier: event.identifier,
    hubId: previous?.hubId ?? "",
    destinationKind: previous?.destinationKind ?? "hub",
    destinationHubId: previous?.destinationHubId ?? null,
    missionType: previous?.missionType ?? "emergency",
    quantity: previous?.quantity ?? 0,
    requiresColdChain: previous?.requiresColdChain ?? false,
    medicationName: previous?.medicationName ?? null,
    alerts: previous?.alerts ?? { battery: false, failure: false, coldChain: false },
    orderStatus: event.status,
    phase: event.phase,
    leg: event.leg,
    latitude: event.latitude,
    longitude: event.longitude,
    altitudeM: event.altitudeM,
    speedKmh: event.speedKmh,
    batteryPercent: event.batteryPercent,
    temperatureC: event.temperatureC,
    etaSeconds: event.etaSeconds,
    linkLost: event.linkLost ?? false,
    // Una lectura vieja no los trae: se conserva lo último conocido.
    altitudeMslM: event.altitudeMslM ?? previous?.altitudeMslM ?? null,
    remoteId: event.remoteId ?? previous?.remoteId ?? null,
  };
}

/**
 * El estado del radar: una foto inicial (REST) y los eventos del socket,
 * agrupados para repintar unas 4 veces por segundo y no en cada mensaje.
 */
export function useRadar(
  source: RadarSource,
  onUnauthorized: () => void,
  listener: ConsoleListener,
) {
  const [data, setData] = useState<RadarData>({
    hubs: [],
    flights: [],
    geofences: [],
    airspace: [],
    connection: "connecting",
    message: null,
    loaded: false,
    clock: null,
  });
  const consoleListener = useRef(listener);
  useEffect(() => {
    consoleListener.current = listener;
  });
  const flights = useRef(new Map<string, RadarFlight>());
  const flushTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const refreshTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const flush = useCallback(() => {
    if (flushTimer.current) return;
    flushTimer.current = setTimeout(() => {
      flushTimer.current = null;
      setData((current) => ({ ...current, flights: [...flights.current.values()] }));
    }, FLUSH_MS);
  }, []);

  const applySnapshot = useCallback(
    (snapshot: Snapshot) => {
      const next = new Map<string, RadarFlight>();
      for (const flight of snapshot.flights) {
        const live = flights.current.get(flight.orderId);
        // Sin Redis el snapshot no trae posición: se conserva la del socket.
        // El socket va más al día que la foto: gana su enlace y su identificación.
        const merged =
          flight.latitude == null && live
            ? { ...live, ...flight, latitude: live.latitude, longitude: live.longitude }
            : flight;
        next.set(flight.orderId, {
          ...merged,
          linkLost: live?.linkLost ?? flight.linkLost ?? false,
          remoteId: live?.remoteId ?? flight.remoteId ?? null,
          altitudeMslM: live?.altitudeMslM ?? flight.altitudeMslM ?? null,
        });
      }
      flights.current = next;
      setData((current) => ({
        ...current,
        hubs: snapshot.hubs,
        geofences: snapshot.geofences,
        // RU-36: el admin puede editar o desactivar una zona; si no cambió
        // nada, se conserva la misma lista para no redibujar el mapa.
        airspace:
          snapshot.airspace && JSON.stringify(snapshot.airspace) !== JSON.stringify(current.airspace)
            ? snapshot.airspace
            : current.airspace,
        flights: [...next.values()],
        loaded: true,
      }));
    },
    [],
  );

  const refresh = useCallback(async () => {
    try {
      applySnapshot(await source.snapshot());
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        onUnauthorized();
        return;
      }
      setData((current) => ({
        ...current,
        loaded: true,
        message: error instanceof Error ? error.message : "No se pudo cargar el radar.",
      }));
    }
  }, [source, applySnapshot, onUnauthorized]);

  const scheduleRefresh = useCallback(() => {
    if (refreshTimer.current) clearTimeout(refreshTimer.current);
    refreshTimer.current = setTimeout(() => void refresh(), 400);
  }, [refresh]);

  useEffect(() => {
    void refresh();
    const interval = setInterval(() => void refresh(), REFRESH_MS);
    const stop = source.connect({
      onConnection: (connection, message) => {
        setData((current) => ({ ...current, connection, message: message ?? null }));
        if (connection === "live") void refresh();
      },
      onTelemetry: (event) => {
        const previous = flights.current.get(event.orderId);
        flights.current.set(event.orderId, fromTelemetry(event, previous));
        // Un vuelo que la foto no conoce: se pide una foto nueva.
        if (!previous) scheduleRefresh();
        flush();
      },
      onStatus: (event) => {
        const previous = flights.current.get(event.orderId);
        if (previous) {
          flights.current.set(event.orderId, { ...previous, orderStatus: event.status });
          flush();
        }
        scheduleRefresh();
      },
      onAlert: (event: AlertEvent) => {
        const previous = flights.current.get(event.orderId);
        if (!previous) return;
        const alerts = { ...previous.alerts };
        if (event.kind === "battery_critical") alerts.battery = true;
        if (event.kind === "failure") alerts.failure = true;
        if (event.kind === "cold_chain") alerts.coldChain = true;
        flights.current.set(event.orderId, { ...previous, alerts });
        flush();
      },
      onClock: (clock) => {
        setData((current) => ({ ...current, clock: { ...clock, receivedAt: Date.now() } }));
      },
      onTimeline: (entry) => consoleListener.current.onTimeline(entry),
      onActors: (actors) => consoleListener.current.onActors(actors),
      onChaos: (chaos) => consoleListener.current.onChaos(chaos),
      onUnidentified: (event) => consoleListener.current.onUnidentified(event),
      onWorld: (what) => {
        // Zonas, apagones e incidentes cambian el mapa y los contadores.
        if (what !== "weather") scheduleRefresh();
        consoleListener.current.onWorld(what);
      },
      onReset: () => {
        // RF-40: los vuelos de antes ya no existen; se pide la foto nueva.
        flights.current = new Map();
        setData((current) => ({ ...current, flights: [] }));
        consoleListener.current.onReset();
        void refresh();
      },
    });
    return () => {
      stop();
      clearInterval(interval);
      if (flushTimer.current) clearTimeout(flushTimer.current);
      if (refreshTimer.current) clearTimeout(refreshTimer.current);
      flushTimer.current = null;
      flights.current = new Map();
    };
  }, [source, refresh, scheduleRefresh, flush]);

  return useMemo(() => data, [data]);
}
