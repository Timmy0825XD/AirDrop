"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ApiError } from "./api";
import type { ClockChange, RadarSource, WorldChange } from "./source";
import type { ConsoleListener } from "./use-radar";
import type {
  ActorsState,
  ChaosState,
  ConsoleIncidentKind,
  GeneratedKind,
  Incident,
  NewSurge,
  NewWeather,
  NewZone,
  PendingAlert,
  ResetSummary,
  TimelineEntry,
  WeatherCell,
} from "./types";

/** Cuántos pasos se muestran; los más viejos se van. */
const TIMELINE_SIZE = 80;
/** Las alertas abiertas se recargan por REST (RF-39), no por polling rápido. */
const ALERTS_REFRESH_MS = 5_000;
/** El clima y los incidentes también llegan por el socket; esto es la red de seguridad. */
const WORLD_REFRESH_MS = 30_000;
const INCIDENTS_SIZE = 40;

export type ConsoleStatus = "loading" | "on" | "off";

export type ConsoleState = {
  status: ConsoleStatus;
  /** Por qué está apagada, tal como lo dice Nest. */
  offMessage: string | null;
  timeline: TimelineEntry[];
  alerts: PendingAlert[];
  /** RF-32: las celdas de clima que rigen. */
  weather: WeatherCell[];
  /** RF-34: los últimos incidentes en vuelo. */
  incidents: Incident[];
  /** RF-37: qué actores simulados están encendidos. */
  actors: ActorsState;
  /** RF-38: el modo caos. */
  chaos: ChaosState;
  busy: boolean;
  error: string | null;
  /** Lo que salió bien de la última orden, para avisarlo un momento. */
  notice: string | null;
  lastReset: ResetSummary | null;
};

const ACTORS_OFF: ActorsState = { autoDispatcher: false, orderFlow: false };
const CHAOS_OFF: ChaosState = { enabled: false, intensity: "medium" };

const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : "No se pudo completar la acción.";

/**
 * La consola de simulación (RU-32): línea de tiempo, alertas pendientes, el
 * clima y los incidentes del mapa, los actores simulados y las órdenes
 * (reloj, eventos, actores y reinicio).
 * Escucha el mismo socket del radar.
 */
export function useConsole(source: RadarSource) {
  const [state, setState] = useState<ConsoleState>({
    status: "loading",
    offMessage: null,
    timeline: [],
    alerts: [],
    weather: [],
    incidents: [],
    actors: ACTORS_OFF,
    chaos: CHAOS_OFF,
    busy: false,
    error: null,
    notice: null,
    lastReset: null,
  });
  const on = state.status === "on";
  const alertsTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const worldTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const loadAlerts = useCallback(async () => {
    try {
      const alerts = await source.control.alerts();
      setState((current) => ({ ...current, alerts }));
    } catch {
      // Se reintenta en la siguiente vuelta; la línea de tiempo sigue.
    }
  }, [source]);

  const loadWorld = useCallback(async () => {
    try {
      const [weather, incidents] = await Promise.all([
        source.control.weather(),
        source.control.incidents(INCIDENTS_SIZE),
      ]);
      setState((current) => ({ ...current, weather, incidents }));
    } catch {
      // Igual que las alertas: la siguiente vuelta lo intenta otra vez.
    }
  }, [source]);

  // Al abrir: si la consola responde, está encendida; un 404 la apaga.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await source.control.clock();
        const [timeline, actors, chaos] = await Promise.all([
          source.control.timeline(TIMELINE_SIZE),
          source.control.actors(),
          source.control.chaos(),
        ]);
        if (!cancelled) {
          setState((current) => ({ ...current, status: "on", timeline, actors, chaos }));
        }
      } catch (error) {
        if (cancelled || (error instanceof ApiError && error.status === 401)) return;
        setState((current) => ({
          ...current,
          status: "off",
          offMessage: messageOf(error),
        }));
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [source]);

  useEffect(() => {
    if (!on) return;
    void loadAlerts();
    void loadWorld();
    const alerts = setInterval(() => void loadAlerts(), ALERTS_REFRESH_MS);
    const world = setInterval(() => void loadWorld(), WORLD_REFRESH_MS);
    return () => {
      clearInterval(alerts);
      clearInterval(world);
    };
  }, [on, loadAlerts, loadWorld]);

  /** Varios avisos seguidos del socket piden una sola recarga. */
  const reloadSoon = useCallback(
    (what: "alerts" | "world") => {
      const timer = what === "alerts" ? alertsTimer : worldTimer;
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => void (what === "alerts" ? loadAlerts() : loadWorld()), 300);
    },
    [loadAlerts, loadWorld],
  );

  const listener: ConsoleListener = useMemo(
    () => ({
      onTimeline: (entry) => {
        setState((current) => ({
          ...current,
          timeline: [entry, ...current.timeline.filter((row) => row.id !== entry.id)].slice(
            0,
            TIMELINE_SIZE,
          ),
        }));
        // Una alerta nueva entra a la bandeja sin esperar la siguiente vuelta.
        if (entry.kind === "alert") reloadSoon("alerts");
      },
      onReset: () => {
        setState((current) => ({
          ...current,
          timeline: [],
          alerts: [],
          weather: [],
          incidents: [],
          // RF-40: el reinicio apaga los actores (el socket lo confirma).
          actors: ACTORS_OFF,
          chaos: CHAOS_OFF,
        }));
      },
      onActors: (actors) => setState((current) => ({ ...current, actors })),
      onChaos: (chaos) => setState((current) => ({ ...current, chaos })),
      onWorld: (what: WorldChange) => {
        if (what === "weather" || what === "incident") reloadSoon("world");
        if (what === "incident") reloadSoon("alerts");
      },
    }),
    [reloadSoon],
  );

  useEffect(
    () => () => {
      if (alertsTimer.current) clearTimeout(alertsTimer.current);
      if (worldTimer.current) clearTimeout(worldTimer.current);
    },
    [],
  );

  const run = useCallback(
    async <T,>(action: () => Promise<T>, notice?: (result: T) => string): Promise<T | null> => {
      setState((current) => ({ ...current, busy: true, error: null, notice: null }));
      try {
        const result = await action();
        setState((current) => ({
          ...current,
          busy: false,
          notice: notice ? notice(result) : null,
        }));
        return result;
      } catch (error) {
        setState((current) => ({ ...current, busy: false, error: messageOf(error) }));
        return null;
      }
    },
    [],
  );

  const setClock = useCallback(
    (change: ClockChange) => run(() => source.control.setClock(change)),
    [run, source],
  );

  const reset = useCallback(async () => {
    const summary = await run(() => source.control.reset());
    if (summary) setState((current) => ({ ...current, lastReset: summary }));
    return summary;
  }, [run, source]);

  const createWeather = useCallback(
    async (input: NewWeather) => {
      const cell = await run(() => source.control.createWeather(input), () => "Clima lanzado.");
      if (cell) void loadWorld();
      return cell;
    },
    [run, source, loadWorld],
  );

  const endWeather = useCallback(
    async (id: string) => {
      const cell = await run(() => source.control.endWeather(id), () => "Clima terminado.");
      if (cell) void loadWorld();
      return cell;
    },
    [run, source, loadWorld],
  );

  const createZone = useCallback(
    (input: NewZone) =>
      run(() => source.control.createZone(input), () => "Geovalla temporal lanzada."),
    [run, source],
  );

  const endZone = useCallback(
    (id: string) => run(() => source.control.endZone(id), () => "Geovalla temporal levantada."),
    [run, source],
  );

  const launchIncident = useCallback(
    async (droneId: string, kind: ConsoleIncidentKind) => {
      const incident = await run(
        () => source.control.launchIncident(droneId, kind),
        (result) => PROTOCOL_NOTICE[result.protocol],
      );
      if (incident) void loadWorld();
      return incident;
    },
    [run, source, loadWorld],
  );

  const startOutage = useCallback(
    (hubId: string, durationMin: number) =>
      run(
        () => source.control.startOutage(hubId, durationMin),
        (outage) => `${outage.name} quedó sin energía.`,
      ),
    [run, source],
  );

  const endOutage = useCallback(
    (hubId: string) =>
      run(() => source.control.endOutage(hubId), (outage) => `Volvió la energía a ${outage.name}.`),
    [run, source],
  );

  const setActors = useCallback(
    async (change: Partial<ActorsState>) => {
      const actors = await run(() => source.control.setActors(change));
      if (actors) setState((current) => ({ ...current, actors }));
      return actors;
    },
    [run, source],
  );

  const setChaos = useCallback(
    async (change: Partial<ChaosState>) => {
      const chaos = await run(() => source.control.setChaos(change));
      if (chaos) setState((current) => ({ ...current, chaos }));
      return chaos;
    },
    [run, source],
  );

  const generateOrder = useCallback(
    (kind: GeneratedKind) =>
      run(
        () => source.control.generateOrder(kind),
        () => (kind === "emergency" ? "Urgencia simulada creada." : "Programado simulado creado."),
      ),
    [run, source],
  );

  const surge = useCallback(
    (input: NewSurge) =>
      run(
        () => source.control.surge(input),
        (result) =>
          result.created.length === result.requested
            ? `Pico lanzado: ${result.requested} urgencias.`
            : `Pico lanzado: ${result.created.length} de ${result.requested} urgencias. ${result.failures[0] ?? ""}`.trim(),
      ),
    [run, source],
  );

  const dismissError = useCallback(
    () => setState((current) => ({ ...current, error: null, notice: null, lastReset: null })),
    [],
  );

  return {
    state,
    listener,
    setClock,
    reset,
    createWeather,
    endWeather,
    createZone,
    endZone,
    launchIncident,
    startOutage,
    endOutage,
    setActors,
    setChaos,
    generateOrder,
    surge,
    dismissError,
  };
}

/** Lo que decidió el sistema, dicho en una línea (RF-34). */
const PROTOCOL_NOTICE: Record<Incident["protocol"], string> = {
  continue: "El dron sigue su misión con alerta.",
  return_to_hub: "El dron vuelve a su central con el paquete.",
  emergency_landing: "El dron aterriza de emergencia.",
  crash: "El dron cayó: sale el rescate.",
  lost: "Se perdió el rastro del dron.",
};
