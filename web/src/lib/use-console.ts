"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ApiError } from "./api";
import type { ClockChange, RadarSource } from "./source";
import type { ConsoleListener } from "./use-radar";
import type { PendingAlert, ResetSummary, TimelineEntry } from "./types";

/** Cuántos pasos se muestran; los más viejos se van. */
const TIMELINE_SIZE = 80;
/** Las alertas abiertas se recargan por REST (RF-39), no por polling rápido. */
const ALERTS_REFRESH_MS = 5_000;

export type ConsoleStatus = "loading" | "on" | "off";

export type ConsoleState = {
  status: ConsoleStatus;
  /** Por qué está apagada, tal como lo dice Nest. */
  offMessage: string | null;
  timeline: TimelineEntry[];
  alerts: PendingAlert[];
  busy: boolean;
  error: string | null;
  lastReset: ResetSummary | null;
};

const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : "No se pudo completar la acción.";

/**
 * La consola de simulación (RU-32): línea de tiempo, alertas pendientes y las
 * órdenes del reloj y del reinicio. Escucha el mismo socket del radar.
 */
export function useConsole(source: RadarSource) {
  const [state, setState] = useState<ConsoleState>({
    status: "loading",
    offMessage: null,
    timeline: [],
    alerts: [],
    busy: false,
    error: null,
    lastReset: null,
  });
  const on = state.status === "on";
  const alertsTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const loadAlerts = useCallback(async () => {
    try {
      const alerts = await source.control.alerts();
      setState((current) => ({ ...current, alerts }));
    } catch {
      // Se reintenta en la siguiente vuelta; la línea de tiempo sigue.
    }
  }, [source]);

  // Al abrir: si la consola responde, está encendida; un 404 la apaga.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await source.control.clock();
        const timeline = await source.control.timeline(TIMELINE_SIZE);
        if (!cancelled) {
          setState((current) => ({ ...current, status: "on", timeline }));
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
    const timer = setInterval(() => void loadAlerts(), ALERTS_REFRESH_MS);
    return () => clearInterval(timer);
  }, [on, loadAlerts]);

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
        if (entry.kind === "alert") {
          // Una alerta nueva entra a la bandeja sin esperar la siguiente vuelta.
          if (alertsTimer.current) clearTimeout(alertsTimer.current);
          alertsTimer.current = setTimeout(() => void loadAlerts(), 300);
        }
      },
      onReset: () => {
        setState((current) => ({ ...current, timeline: [], alerts: [] }));
      },
    }),
    [loadAlerts],
  );

  useEffect(
    () => () => {
      if (alertsTimer.current) clearTimeout(alertsTimer.current);
    },
    [],
  );

  const run = useCallback(async <T,>(action: () => Promise<T>): Promise<T | null> => {
    setState((current) => ({ ...current, busy: true, error: null }));
    try {
      const result = await action();
      setState((current) => ({ ...current, busy: false }));
      return result;
    } catch (error) {
      setState((current) => ({ ...current, busy: false, error: messageOf(error) }));
      return null;
    }
  }, []);

  const setClock = useCallback(
    (change: ClockChange) => run(() => source.control.setClock(change)),
    [run, source],
  );

  const reset = useCallback(async () => {
    const summary = await run(() => source.control.reset());
    if (summary) setState((current) => ({ ...current, lastReset: summary }));
    return summary;
  }, [run, source]);

  const dismissError = useCallback(
    () => setState((current) => ({ ...current, error: null, lastReset: null })),
    [],
  );

  return { state, listener, setClock, reset, dismissError };
}
