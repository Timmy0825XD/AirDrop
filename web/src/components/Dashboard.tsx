"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import type { RadarSource } from "@/lib/source";
import type { Selection } from "@/lib/types";
import { usePolled } from "@/lib/use-polled";
import { useRadar } from "@/lib/use-radar";
import { FlightPanel } from "./FlightPanel";
import { AlertIcon, DroneIcon } from "./icons";
import { Legend } from "./Legend";
import { HubPanel } from "./HubPanel";
import { RadarMap } from "./map/RadarMap";
import { TopBar } from "./TopBar";

const FLIGHT_REFRESH_MS = 8_000;

type Props = {
  source: RadarSource;
  userName: string | null;
  onLogout: () => void;
};

/** El radar completo: mapa a pantalla completa y panel lateral a la derecha. */
export function Dashboard({ source, userName, onLogout }: Props) {
  const data = useRadar(source, onLogout);
  const [selection, setSelection] = useState<Selection>(null);
  const [showGeofences, setShowGeofences] = useState(true);

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

  const live = flightId ? data.flights.find((f) => f.orderId === flightId) : undefined;

  return (
    <main
      data-panel={selection ? "" : undefined}
      className="relative h-dvh w-full overflow-hidden bg-backdrop"
    >
      <RadarMap
        hubs={data.hubs}
        flights={data.flights}
        geofences={data.geofences}
        showGeofences={showGeofences}
        selection={selection}
        routes={routes}
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
      />

      {/* Velo del tono de la app; no capta clics. */}
      <div className="map-vignette pointer-events-none absolute inset-0 z-[1]" />
      <Legend />

      {data.message && (
        <p
          role="alert"
          className="glass rise-in absolute left-1/2 top-[100px] z-30 flex max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-2xl !border-danger/40 px-4 py-3 text-sm font-medium text-danger"
        >
          <AlertIcon size={18} className="shrink-0" />
          {data.message}
        </p>
      )}
      {data.loaded && !data.flights.length && !selection && (
        <p className="glass rise-in pointer-events-none absolute bottom-24 left-1/2 z-10 flex w-max max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-full px-4 py-2.5 text-sm text-muted 2xl:bottom-5">
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
    </main>
  );
}
