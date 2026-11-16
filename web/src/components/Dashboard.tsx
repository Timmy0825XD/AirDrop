"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { circlePolygon, distanceKm } from "@/lib/geo";
import { useSimNow } from "@/lib/sim-time";
import type { RadarSource } from "@/lib/source";
import type { PendingAlert, Selection, TimelineEntry } from "@/lib/types";
import { useConsole } from "@/lib/use-console";
import { usePolled } from "@/lib/use-polled";
import { useRadar } from "@/lib/use-radar";
import { useTheme } from "@/lib/use-theme";
import { useDeliveryPoints } from "@/lib/use-region";
import { AlertsTray } from "./AlertsTray";
import { ActorsMenu } from "./ActorsMenu";
import { ClockControl } from "./ClockControl";
import { EventComposer, EventDock, type EventLaunch, type EventTool } from "./EventDock";
import { DaylightChip } from "./DaylightChip";
import { EventPanel } from "./EventPanel";
import { FlightPanel } from "./FlightPanel";
import { AlertIcon, CheckIcon } from "./icons";
import { HubPanel } from "./HubPanel";
import { RadarMap, type EventDraft, type MapFocus } from "./map/RadarMap";
import { AirspacePanel, ContactPanel, PointPanel } from "./RegionPanel";
import { ResetDialog } from "./ResetDialog";
import { TimelinePanel } from "./TimelinePanel";
import { TopBar } from "./TopBar";

const FLIGHT_REFRESH_MS = 8_000;
/** La luz del día cambia despacio: basta una lectura por minuto. */
const DAYLIGHT_REFRESH_MS = 60_000;
/** Cuánto se quedan los avisos de la consola. */
const NOTICE_MS = 7_000;
/** Incidentes, apagones y ráfagas en un ensayo no tienen backend. */
const DEMO_BLOCKED = "En modo demostración no se lanzan incidentes ni apagones.";
/** RF-36: el backend solo crea urgencias hacia puntos dentro del círculo. */
const SURGE_NEEDS_POINT = "El pico necesita un punto de entrega disponible dentro del círculo.";

type Props = {
  source: RadarSource;
  userName: string | null;
  onLogout: () => void;
};

/** En una TV la línea de tiempo arranca abierta; en un celular, plegada. */
const startsOpen = () =>
  typeof window === "undefined" || window.matchMedia("(min-width: 1024px)").matches;

/**
 * La consola en la TV: el mapa a pantalla completa y, flotando encima como
 * tarjetas, la barra con el reloj, la línea de tiempo a la izquierda, las
 * alertas, el detalle a la derecha y, abajo, la barra para lanzar eventos
 * sobre el mapa (CU-38).
 */
export function Dashboard({ source, userName, onLogout }: Props) {
  const consola = useConsole(source);
  const { theme, toggle: toggleTheme } = useTheme();
  const data = useRadar(source, onLogout, consola.listener);
  // RF-45: los puntos se recargan al reiniciar el escenario.
  const region = useDeliveryPoints(source, consola.state.lastReset);
  const [selection, setSelection] = useState<Selection>(null);
  const [showGeofences, setShowGeofences] = useState(true);
  const [timelineOpen, setTimelineOpen] = useState(startsOpen);
  const [focus, setFocus] = useState<MapFocus | null>(null);
  const [confirmReset, setConfirmReset] = useState(false);
  const [tool, setTool] = useState<EventTool | null>(null);
  const [draft, setDraft] = useState<EventDraft | null>(null);

  // RF-31: las cuentas regresivas del mapa van en hora simulada; cada 10 s basta.
  const simNow = useSimNow(data.clock);
  // Mientras llega el primer `clock` del backend, la hora de abrir la página.
  const [openedAt] = useState(() => Date.now());
  const mapNow = useMemo(() => {
    const now = simNow ?? openedAt;
    return now - (now % 10_000);
  }, [simNow, openedAt]);

  const flightId = selection?.kind === "flight" ? selection.id : null;
  const loadFlight = useCallback(() => source.flight(flightId as string), [source, flightId]);
  const detail = usePolled(loadFlight, flightId, FLIGHT_REFRESH_MS);

  // RF-44: se vuelve a leer al cambiar la velocidad del reloj o al reiniciar.
  const loadDaylight = useCallback(() => source.daylight(), [source]);
  const daylightKey = `day-${data.clock?.speed ?? 1}-${data.clock?.paused ?? false}-${consola.state.lastReset ? "r" : ""}`;
  const daylight = usePolled(loadDaylight, daylightKey, DAYLIGHT_REFRESH_MS);

  // Solo el vuelo elegido dibuja su ruta (y la de antes, si cambió en el aire).
  const routes = useMemo(
    () => ({
      route: detail.data?.route ?? null,
      returnRoute: detail.data?.returnRoute ?? null,
      previous: [detail.data?.previousRoute, detail.data?.previousReturnRoute].filter(
        (path): path is Array<[number, number]> => Boolean(path),
      ),
    }),
    [detail.data],
  );

  const closeTool = useCallback(() => {
    setTool(null);
    setDraft(null);
  }, []);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      if (tool) closeTool();
      else setSelection(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [tool, closeTool]);

  // El anillo del foco se apaga solo.
  useEffect(() => {
    if (!focus) return;
    const timer = setTimeout(() => setFocus(null), 6_000);
    return () => clearTimeout(timer);
  }, [focus]);

  const { lastReset, error, notice } = consola.state;
  const { dismissError } = consola;
  useEffect(() => {
    if (!lastReset && !error && !notice) return;
    const timer = setTimeout(dismissError, NOTICE_MS);
    return () => clearTimeout(timer);
  }, [lastReset, error, notice, dismissError]);
  const { error: regionError, dismiss: dismissRegion } = region;
  useEffect(() => {
    if (!regionError) return;
    const timer = setTimeout(dismissRegion, NOTICE_MS);
    return () => clearTimeout(timer);
  }, [regionError, dismissRegion]);

  /** Lleva el mapa al punto y, si el pedido sigue volando, abre su vuelo. */
  const show = useCallback(
    (point: {
      orderId: string | null;
      hubId?: string | null;
      latitude: number | null;
      longitude: number | null;
    }) => {
      const live = point.orderId ? data.flights.find((f) => f.orderId === point.orderId) : undefined;
      if (live) setSelection({ kind: "flight", id: live.orderId });
      // Sin posición del paso, la central que lo protagoniza (p. ej. la que autorizó).
      const hub = point.hubId ? data.hubs.find((row) => row.id === point.hubId) : undefined;
      const latitude = live?.latitude ?? point.latitude ?? hub?.latitude ?? null;
      const longitude = live?.longitude ?? point.longitude ?? hub?.longitude ?? null;
      if (latitude != null && longitude != null) {
        setFocus({ latitude, longitude, key: Date.now() });
      }
    },
    [data.flights, data.hubs],
  );

  const pickEntry = useCallback((entry: TimelineEntry) => show(entry), [show]);
  const pickAlert = useCallback((alert: PendingAlert) => show(alert), [show]);

  const doReset = useCallback(async () => {
    const summary = await consola.reset();
    if (summary) {
      setConfirmReset(false);
      setSelection(null);
      setFocus(null);
      closeTool();
    }
  }, [consola, closeTool]);

  const chooseTool = useCallback((next: EventTool | null) => {
    setTool(next);
    setDraft(null);
    if (next) setSelection(null);
  }, []);

  const availablePoints = useMemo(
    () => region.points.filter((point) => point.available),
    [region.points],
  );

  const pick = useCallback(
    (point: { latitude: number; longitude: number }) => {
      if (!tool || tool === "unidentified") return;
      setDraft((current) => {
        const radiusKm = current?.radiusKm ?? (tool === "zone" || tool === "surge" ? 1 : 3);
        // RF-36: un pico sin punto de entrega adentro no crea nada: el centro
        // se pega al punto disponible más cercano.
        let center = point;
        if (tool === "surge" && availablePoints.length) {
          const nearest = availablePoints.reduce((best, row) =>
            distanceKm(point, row) < distanceKm(point, best) ? row : best,
          );
          if (distanceKm(point, nearest) > radiusKm) {
            center = { latitude: nearest.latitude, longitude: nearest.longitude };
          }
        }
        return { kind: tool, ...center, radiusKm };
      });
    },
    [tool, availablePoints],
  );

  // Al achicar el radio el punto puede quedar afuera: se avisa y no se lanza.
  const surgeBlocked =
    draft?.kind === "surge" &&
    !availablePoints.some((point) => distanceKm(draft, point) <= draft.radiusKm)
      ? SURGE_NEEDS_POINT
      : null;

  const launch = useCallback(
    async (event: EventLaunch) => {
      if (event.tool === "unidentified") {
        // RF-36: cruza el corredor de un dron en el aire; llega por el socket.
        const contact = await consola.launchUnidentified(event.durationMin);
        if (contact) {
          closeTool();
          setSelection({ kind: "contact", id: contact.id });
        }
        return;
      }
      if (event.tool === "surge") {
        // RF-36: las urgencias llegan al mapa y a la línea de tiempo por el socket.
        const result = await consola.surge({
          latitude: event.latitude,
          longitude: event.longitude,
          radiusKm: Math.round(event.radiusKm * 10) / 10,
          count: event.count,
        });
        if (result) closeTool();
        return;
      }
      if (event.tool === "zone") {
        const zone = await consola.createZone({
          name: event.name,
          reason: event.name,
          polygon: circlePolygon(event.latitude, event.longitude, event.radiusKm, 16),
          durationMin: event.durationMin,
        });
        if (zone) {
          closeTool();
          setSelection({ kind: "zone", id: zone.id });
        }
        return;
      }
      const cell = await consola.createWeather({
        kind: event.tool,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: Math.round(event.radiusKm * 10) / 10,
        durationMin: event.durationMin,
        ...(event.tool === "wind"
          ? {
              windSpeedMs: event.windSpeedMs,
              // Las ráfagas, un 30 % sobre el sostenido (tope del backend: 50).
              windGustMs: Math.min(50, Math.round(event.windSpeedMs * 1.3)),
              windFromDeg: event.windFromDeg,
            }
          : {}),
      });
      if (cell) {
        closeTool();
        setSelection({ kind: "weather", id: cell.id });
      }
    },
    [consola, closeTool],
  );

  const consoleOn = consola.state.status === "on";
  const offReason = consoleOn
    ? null
    : (consola.state.offMessage ?? "La consola de simulación está apagada.");
  const realBlocked = offReason ?? (source.demo ? DEMO_BLOCKED : null);

  const live = flightId ? data.flights.find((f) => f.orderId === flightId) : undefined;
  // La línea de tiempo flota sobre el mapa: el mapa centra lo suyo a su derecha.
  const leftInset = timelineOpen ? 420 : 0;
  const panelOpen = selection != null;

  // RF-34: drones caídos o aterrizando de emergencia, con su nombre de la bandeja.
  const landings = useMemo(() => {
    const names = new Map(consola.state.alerts.map((alert) => [alert.droneId, alert.identifier]));
    for (const flight of data.flights) names.set(flight.droneId, flight.identifier);
    return consola.state.incidents
      .filter((incident) => incident.outcome === "landing" || incident.outcome === "grounded")
      .map((incident) => ({ incident, identifier: names.get(incident.droneId) ?? "Dron" }));
  }, [consola.state.incidents, consola.state.alerts, data.flights]);

  const selectedWeather =
    selection?.kind === "weather"
      ? (consola.state.weather.find((cell) => cell.id === selection.id) ?? null)
      : null;
  const selectedZone =
    selection?.kind === "zone"
      ? (data.geofences.find((zone) => zone.id === selection.id) ?? null)
      : null;
  const selectedHub =
    selection?.kind === "hub" ? data.hubs.find((hub) => hub.id === selection.id) : undefined;
  const selectedAirspace =
    selection?.kind === "airspace"
      ? (data.airspace.find((zone) => zone.code === selection.id) ?? null)
      : null;
  const selectedPoint =
    selection?.kind === "point"
      ? (region.points.find((point) => point.id === selection.id) ?? null)
      : null;
  const selectedContact =
    selection?.kind === "contact"
      ? (consola.state.contacts.find((contact) => contact.id === selection.id) ?? null)
      : null;
  const hubOutage =
    selectedHub?.powerOutageUntil && Date.parse(selectedHub.powerOutageUntil) > mapNow
      ? selectedHub.powerOutageUntil
      : null;

  const endEvent = useCallback(async () => {
    const ended =
      selection?.kind === "weather"
        ? await consola.endWeather(selection.id)
        : selection?.kind === "zone"
          ? await consola.endZone(selection.id)
          : null;
    if (ended) setSelection(null);
  }, [consola, selection]);

  const toast = consola.state.error ?? region.error ?? data.message;
  const success =
    consola.state.notice ??
    (consola.state.lastReset
      ? `Escenario reiniciado: ${consola.state.lastReset.orders} pedidos borrados y ${consola.state.lastReset.drones} drones en su central.`
      : null);


  return (
    <main
      data-panel={panelOpen ? "" : undefined}
      className="relative h-dvh w-full overflow-hidden bg-ground"
    >
      <TopBar
        theme={theme}
        onToggleTheme={toggleTheme}
        connection={data.connection}
        demo={source.demo}
        userName={userName}
        showGeofences={showGeofences}
        onToggleGeofences={() => setShowGeofences((value) => !value)}
        onLogout={onLogout}
        onReset={consoleOn ? () => setConfirmReset(true) : null}
        busy={consola.state.busy}
        clock={
          <ClockControl
            clock={data.clock}
            status={consola.state.status}
            offMessage={consola.state.offMessage}
            busy={consola.state.busy}
            onChange={(change) => void consola.setClock(change)}
          />
        }
        daylight={<DaylightChip day={daylight.data} />}
        actors={
          consoleOn ? (
            <ActorsMenu
              actors={consola.state.actors}
              chaos={consola.state.chaos}
              busy={consola.state.busy}
              onChange={(change) => void consola.setActors(change)}
              onChaos={(change) => void consola.setChaos(change)}
              onGenerate={(kind) => void consola.generateOrder(kind)}
            />
          ) : null
        }
      />

      <div className="absolute inset-0">
        <TimelinePanel
          open={timelineOpen}
          status={consola.state.status}
          offMessage={consola.state.offMessage}
          entries={consola.state.timeline}
          onToggle={() => setTimelineOpen((value) => !value)}
          onPick={pickEntry}
        />

        <div className="absolute inset-0">
          <RadarMap
            key={theme}
            hubs={data.hubs}
            flights={data.flights}
            geofences={data.geofences}
            airspace={data.airspace}
            points={region.points}
            showGeofences={showGeofences}
            selection={selection}
            routes={routes}
            insetLeft={leftInset}
            panelOpen={panelOpen}
            focus={focus}
            onSelect={setSelection}
            weather={consola.state.weather}
            contacts={consola.state.contacts}
            landings={landings}
            now={mapNow}
            picking={tool != null && tool !== "unidentified"}
            draft={draft}
            onPick={pick}
          />

          <AlertsTray
            alerts={consola.state.alerts}
            className={`left-3 right-3 top-[84px] sm:top-[96px] ${timelineOpen ? "lg:left-[440px]" : ""} ${panelOpen ? "sm:right-[440px]" : ""}`}
            onPick={pickAlert}
          />

          <EventDock tool={tool} disabled={!consoleOn} onTool={chooseTool} />
          {tool && (
            <EventComposer
              key={tool}
              tool={tool}
              center={draft ? { latitude: draft.latitude, longitude: draft.longitude } : null}
              busy={consola.state.busy}
              blocked={surgeBlocked}
              onDraft={setDraft}
              onLaunch={(event) => void launch(event)}
              onClose={closeTool}
            />
          )}

          {toast && (
            <p
              role="alert"
              className="enter-up absolute left-1/2 top-[96px] z-50 flex max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-lg border border-danger/45 bg-panel px-4 py-2.5 text-[14px] text-danger shadow-[0_10px_30px_-14px_var(--shadow)]"
            >
              <AlertIcon size={17} className="shrink-0" />
              {toast}
            </p>
          )}
          {success && !toast && (
            <p
              role="status"
              className="enter-up absolute left-1/2 top-[96px] z-30 flex max-w-[calc(100%-2rem)] -translate-x-1/2 items-center gap-2.5 rounded-lg border border-success/40 bg-panel px-4 py-2.5 text-[14px] text-text shadow-[0_10px_30px_-14px_var(--shadow)]"
            >
              <CheckIcon size={17} className="shrink-0 text-success" />
              {success}
            </p>
          )}
          {data.loaded && !data.flights.length && !selection && !tool && (
            <p className="pointer-events-none absolute bottom-[96px] left-1/2 z-10 w-max max-w-[calc(100%-2rem)] -translate-x-1/2 text-center text-[13px] text-muted [text-shadow:0_1px_8px_var(--ground)]">
              No hay drones en vuelo. Toca un nodo para ver su flota.
            </p>
          )}

      {selection?.kind === "hub" && (
        <HubPanel
          key={selection.id}
          source={source}
          hubId={selection.id}
          networkRole={selectedHub?.networkRole ?? null}
          onSelect={setSelection}
          outageUntil={hubOutage}
          busy={consola.state.busy}
          eventBlocked={realBlocked}
          onStartOutage={(hubId, minutes) => void consola.startOutage(hubId, minutes)}
          onEndOutage={(hubId) => void consola.endOutage(hubId)}
        />
      )}
      {selection?.kind === "flight" && (
        <FlightPanel
          key={selection.id}
          detail={detail.data}
          error={detail.error}
          live={live}
          onSelect={setSelection}
          busy={consola.state.busy}
          incidentBlocked={realBlocked}
          onIncident={(droneId, kind) => void consola.launchIncident(droneId, kind)}
        />
      )}
      {selection?.kind === "airspace" && (
        <AirspacePanel key={selection.id} zone={selectedAirspace} onSelect={setSelection} />
      )}
      {selection?.kind === "point" && (
        <PointPanel
          key={selection.id}
          point={selectedPoint}
          hubName={data.hubs.find((hub) => hub.id === selectedPoint?.hubId)?.name ?? null}
          busy={region.busy}
          blocked={source.demo ? null : offReason}
          onToggle={(id, active) => void region.setActive(id, active)}
          onSelect={setSelection}
        />
      )}
      {selection?.kind === "contact" && (
        <ContactPanel
          key={selection.id}
          contact={selectedContact}
          now={mapNow}
          onSelect={setSelection}
        />
      )}
      {(selection?.kind === "weather" || selection?.kind === "zone") && (
        <EventPanel
          key={selection.id}
          weather={selectedWeather}
          zone={selectedZone}
          now={mapNow}
          busy={consola.state.busy}
          canEnd={consoleOn}
          onEnd={() => void endEvent()}
          onSelect={setSelection}
        />
      )}

        </div>
      </div>

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
