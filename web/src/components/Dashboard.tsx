"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import type { RadarSource } from "@/lib/source";
import type { PendingAlert, Selection, TimelineEntry } from "@/lib/types";
import { useConsole } from "@/lib/use-console";
import { usePolled } from "@/lib/use-polled";
import { useRadar } from "@/lib/use-radar";
import { AlertsTray } from "./AlertsTray";
import { ClockControl } from "./ClockControl";
import { FlightPanel } from "./FlightPanel";
import { AlertIcon, CheckIcon, DroneIcon } from "./icons";
import { Legend } from "./Legend";
import { HubPanel } from "./HubPanel";
import { RadarMap, type MapFocus } from "./map/RadarMap";
import { ResetDialog } from "./ResetDialog";
import { TimelinePanel } from "./TimelinePanel";
import { TopBar } from "./TopBar";

const FLIGHT_REFRESH_MS = 8_000;
/** Lo que mide la línea de tiempo abierta, más su margen. */
const TIMELINE_PX = 396;
/** Cuánto se queda el aviso del reinicio. */
const NOTICE_MS = 7_000;

type Props = {
  source: RadarSource;
  userName: string | null;
  onLogout: () => void;
};

/** En una TV la línea de tiempo arranca abierta; en un celular, plegada. */
const startsOpen = () =>
  typeof window === "undefined" || window.matchMedia("(min-width: 1024px)").matches;

/**
 * La consola en la TV: el mapa a pantalla completa, la barra con el reloj, la
 * línea de tiempo a la izquierda, las alertas arriba y el detalle a la derecha.
 */
export function Dashboard({ source, userName, onLogout }: Props) {
  const consola = useConsole(source);
  const data = useRadar(source, onLogout, consola.listener);
  const [selection, setSelection] = useState<Selection>(null);
  const [showGeofences, setShowGeofences] = useState(true);
  const [timelineOpen, setTimelineOpen] = useState(startsOpen);
  const [focus, setFocus] = useState<MapFocus | null>(null);
  const [confirmReset, setConfirmReset] = useState(false);

  const flightId = selection?.kind === "flight" ? selection.id : null;
  const loadFlight = useCallback(() => source.flight(flightId as string), [source, flightId]);
  const detail = usePolled(loadFlight, flightId, FLIGHT_REFRESH_MS);

  // Solo el vuelo elegido dibuja su ruta; los demás van sin ella.
  const routes = useMemo(
    () => ({
      route: detail.data?.route ?? null,
      returnRoute: detail.data?.returnRoute ?? null,
    }),
    [detail.data],
  );

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSelection(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // El anillo del foco se apaga solo.
  useEffect(() => {
    if (!focus) return;
    const timer = setTimeout(() => setFocus(null), 6_000);
    return () => clearTimeout(timer);
  }, [focus]);

  const { lastReset, error } = consola.state;
  const { dismissError } = consola;
  useEffect(() => {
    if (!lastReset && !error) return;
    const timer = setTimeout(dismissError, NOTICE_MS);
    return () => clearTimeout(timer);
  }, [lastReset, error, dismissError]);

  /** Lleva el mapa al punto y, si el pedido sigue volando, abre su vuelo. */
  const show = useCallback(
    (point: { orderId: string | null; latitude: number | null; longitude: number | null }) => {
      const live = point.orderId ? data.flights.find((f) => f.orderId === point.orderId) : undefined;
      if (live) setSelection({ kind: "flight", id: live.orderId });
      const latitude = live?.latitude ?? point.latitude;
      const longitude = live?.longitude ?? point.longitude;
      if (latitude != null && longitude != null) {
        setFocus({ latitude, longitude, key: Date.now() });
      }
    },
    [data.flights],
  );

  const pickEntry = useCallback((entry: TimelineEntry) => show(entry), [show]);
  const pickAlert = useCallback((alert: PendingAlert) => show(alert), [show]);

  const doReset = useCallback(async () => {
    const summary = await consola.reset();
    if (summary) {
      setConfirmReset(false);
      setSelection(null);
      setFocus(null);
    }
  }, [consola]);

  const live = flightId ? data.flights.find((f) => f.orderId === flightId) : undefined;
  const leftInset = timelineOpen ? TIMELINE_PX : 0;
  const panelOpen = selection != null;

  return (
    <main
      data-panel={panelOpen ? "" : undefined}
      data-timeline={timelineOpen ? "" : undefined}
      className="relative h-dvh w-full overflow-hidden bg-backdrop"
    >
      <RadarMap
        hubs={data.hubs}
        flights={data.flights}
        geofences={data.geofences}
        showGeofences={showGeofences}
        selection={selection}
        routes={routes}
        insetLeft={leftInset}
        focus={focus}
        onSelect={setSelection}
      />
      <TopBar
        hubs={data.hubs}
        flights={data.flights}
        connection={data.connection}
        demo={source.demo}
        userName={userName}
        showGeofences={showGeofences}
        onToggleGeofences={() => setShowGeofences((value) => !value)}
        onLogout={onLogout}
        clock={
          <ClockControl
            clock={data.clock}
            status={consola.state.status}
            offMessage={consola.state.offMessage}
            busy={consola.state.busy}
            onChange={(change) => void consola.setClock(change)}
            onReset={() => setConfirmReset(true)}
          />
        }
      />

      {/* Velo del tono de la app; no capta clics. */}
      <div className="map-vignette pointer-events-none absolute inset-0 z-[1]" />
      <Legend shifted={timelineOpen} />

      <TimelinePanel
        open={timelineOpen}
        status={consola.state.status}
        offMessage={consola.state.offMessage}
        entries={consola.state.timeline}
        onToggle={() => setTimelineOpen((value) => !value)}
        onPick={pickEntry}
      />
      <AlertsTray
        alerts={consola.state.alerts}
        className={`left-3 right-3 ${timelineOpen ? "sm:left-[412px]" : "sm:left-4"} ${panelOpen ? "sm:right-[432px]" : "sm:right-4"}`}
        onPick={pickAlert}
      />

      {(data.message || consola.state.error) && (
        <p
          role="alert"
          className="glass rise-in absolute bottom-24 left-1/2 z-50 flex max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-2xl !border-danger/40 px-4 py-3 text-sm font-medium text-danger"
        >
          <AlertIcon size={18} className="shrink-0" />
          {consola.state.error ?? data.message}
        </p>
      )}
      {consola.state.lastReset && !consola.state.error && (
        <p
          role="status"
          className="glass rise-in absolute bottom-24 left-1/2 z-30 flex max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-2xl !border-success/40 px-4 py-3 text-sm font-medium text-success"
        >
          <CheckIcon size={18} className="shrink-0" />
          Escenario reiniciado: {consola.state.lastReset.orders} pedidos borrados y{" "}
          {consola.state.lastReset.drones} drones en su central.
        </p>
      )}
      {data.loaded && !data.flights.length && !selection && (
        <p className="glass rise-in pointer-events-none absolute bottom-24 left-1/2 z-10 flex w-max max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-full px-4 py-2.5 text-sm text-muted">
          <DroneIcon size={16} className="shrink-0 text-accent" />
          No hay drones en vuelo ahora. Toca una central para ver su flota.
        </p>
      )}

      {selection?.kind === "hub" && (
        <HubPanel key={selection.id} source={source} hubId={selection.id} onSelect={setSelection} />
      )}
      {selection?.kind === "flight" && (
        <FlightPanel
          key={selection.id}
          detail={detail.data}
          error={detail.error}
          live={live}
          onSelect={setSelection}
        />
      )}

      {confirmReset && (
        <ResetDialog
          demo={source.demo}
          busy={consola.state.busy}
          onCancel={() => setConfirmReset(false)}
          onConfirm={() => void doReset()}
        />
      )}
    </main>
  );
}
