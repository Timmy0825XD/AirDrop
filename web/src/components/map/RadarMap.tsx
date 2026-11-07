"use client";

import "maplibre-gl/dist/maplibre-gl.css";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Map, {
  Layer,
  Source,
  type MapLayerMouseEvent,
  type MapRef,
} from "react-map-gl/maplibre";
import { setWorkerUrl, type StyleSpecification } from "maplibre-gl";
import { circlePolygon } from "@/lib/geo";
import { COLORS } from "@/lib/theme";
import type {
  Corridor,
  Geofence,
  HubSummary,
  Incident,
  RadarFlight,
  Selection,
  WeatherCell,
  WeatherKind,
} from "@/lib/types";
import { MinusIcon, PlusIcon, RecenterIcon } from "../icons";
import { GlassButton } from "../ui";
import {
  ICON_ALERT,
  ICON_OUTBOUND,
  ICON_RETURN,
  ICON_WIND,
  addDroneIcons,
} from "./drone-icons";
import { IncidentMarker, WeatherMarker, ZoneMarker } from "./EventMarkers";
import { HubMarker } from "./HubMarker";
import { useDroneTracks } from "./use-drone-tracks";

// El worker lo copia `scripts/copy-maplibre.mjs` a /public antes de dev y build.
if (typeof window !== "undefined") setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

const VALLEDUPAR = { longitude: -73.2532, latitude: 10.4631, zoom: 11 };
/** El panel lateral mide 400 px más su margen: el mapa deja ese espacio al encuadrar. */
const PANEL_PX = 416;
/** El halo del dron y la tormenta laten en este ciclo (como `DroneMarker`). */
const PULSE_MS = 1_800;

/** Un punto que la consola pide mostrar (un paso de la línea de tiempo o una alerta). */
export type MapFocus = { latitude: number; longitude: number; key: number };

/** El evento que se está componiendo: su centro y su radio, para verlo antes de lanzarlo. */
export type EventDraft = {
  kind: WeatherKind | "zone" | "surge";
  latitude: number;
  longitude: number;
  radiusKm: number;
};

/**
 * Mapa base oscuro de Esri (sin API key). Se puede cambiar con
 * `NEXT_PUBLIC_TILES_URL` (plantilla `{z}/{x}/{y}`) si el proveedor cambia.
 */
const ESRI = "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas";
const BASE_TILES =
  process.env.NEXT_PUBLIC_TILES_URL ?? `${ESRI}/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}`;

const STYLE: StyleSpecification = {
  version: 8,
  sources: {
    base: {
      type: "raster",
      tiles: [BASE_TILES],
      tileSize: 256,
      maxzoom: 16,
      attribution: "Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors",
    },
    labels: {
      type: "raster",
      tiles: [`${ESRI}/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}`],
      tileSize: 256,
      maxzoom: 16,
    },
  },
  // El gris de Esri sobre un fondo grafito turquesa, como el mapa de la app.
  layers: [
    { id: "tint", type: "background", paint: { "background-color": COLORS.mapTint } },
    {
      id: "base",
      type: "raster",
      source: "base",
      paint: {
        "raster-opacity": 0.62,
        "raster-brightness-max": 0.85,
        "raster-contrast": 0.12,
        "raster-fade-duration": 200,
      },
    },
    { id: "labels", type: "raster", source: "labels", paint: { "raster-opacity": 0.7 } },
  ],
};

const EMPTY = { type: "FeatureCollection", features: [] } as const;

type Props = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  geofences: Geofence[];
  showGeofences: boolean;
  selection: Selection;
  routes: {
    route: Corridor | null;
    returnRoute: Corridor | null;
    /** RF-33: lo que iba a volar antes de cambiar la ruta. */
    previous: Array<Array<[number, number]>>;
  };
  /** Espacio que tapan la línea de tiempo (izquierda) y el panel (derecha). */
  insetLeft: number;
  panelOpen: boolean;
  focus: MapFocus | null;
  onSelect: (selection: Selection) => void;
  /** RF-32: las celdas de clima que rigen. */
  weather: WeatherCell[];
  /** RF-34: drones caídos o aterrizando de emergencia que esperan rescate. */
  landings: Array<{ incident: Incident; identifier: string }>;
  /** Hora simulada (ms) para las cuentas regresivas. */
  now: number;
  /** CU-38: con una herramienta elegida, tocar el mapa marca el centro. */
  picking: boolean;
  draft: EventDraft | null;
  onPick: (point: { latitude: number; longitude: number }) => void;
};

function lineOf(coordinates: Array<[number, number]> | undefined, leg: string) {
  return coordinates && coordinates.length >= 2
    ? [
        {
          type: "Feature" as const,
          properties: { leg },
          geometry: { type: "LineString" as const, coordinates },
        },
      ]
    : [];
}

const reducedMotion = () =>
  typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

export function RadarMap({
  hubs,
  flights,
  geofences,
  showGeofences,
  selection,
  routes,
  insetLeft,
  panelOpen,
  focus,
  onSelect,
  weather,
  landings,
  now,
  picking,
  draft,
  onPick,
}: Props) {
  const mapRef = useRef<MapRef>(null);
  const [ready, setReady] = useState(false);
  const [hovering, setHovering] = useState(false);
  const fitted = useRef(false);

  useDroneTracks(mapRef, flights, ready);

  const onLoad = useCallback(() => {
    const map = mapRef.current?.getMap();
    if (!map) return;
    addDroneIcons(map);
    setReady(true);
  }, []);

  /** Encuadra todas las centrales: al llegar la primera vez y con "Recentrar". */
  const fitHubs = useCallback(
    (duration: number) => {
      const map = mapRef.current;
      if (!map || !hubs.length) return;
      const lngs = hubs.map((hub) => hub.longitude);
      const lats = hubs.map((hub) => hub.latitude);
      map.fitBounds(
        [
          [Math.min(...lngs), Math.min(...lats)],
          [Math.max(...lngs), Math.max(...lats)],
        ],
        {
          padding: {
            top: 140,
            bottom: 140,
            left: 80 + insetLeft,
            right: (panelOpen ? PANEL_PX : 0) + 120,
          },
          maxZoom: 13,
          duration,
        },
      );
    },
    [hubs, insetLeft, panelOpen],
  );

  useEffect(() => {
    if (!ready || fitted.current || !hubs.length) return;
    fitted.current = true;
    fitHubs(0);
  }, [ready, hubs, fitHubs]);

  // Al elegir una central, el mapa la lleva al centro del espacio libre.
  const selectedHubId = selection?.kind === "hub" ? selection.id : null;
  useEffect(() => {
    const hub = hubs.find((row) => row.id === selectedHubId);
    if (!hub) return;
    mapRef.current?.easeTo({
      center: [hub.longitude, hub.latitude],
      padding: { left: insetLeft, right: PANEL_PX },
      duration: 600,
    });
    // El panel ya abierto no vuelve a mover el mapa al plegar la línea de tiempo.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedHubId, hubs]);

  // RF-39: la consola lleva el mapa a donde pasó algo.
  useEffect(() => {
    const map = mapRef.current;
    if (!focus || !map) return;
    map.easeTo({
      center: [focus.longitude, focus.latitude],
      zoom: Math.max(map.getZoom(), 13),
      padding: { left: insetLeft, right: PANEL_PX },
      duration: 700,
    });
    // Solo cuando llega un foco nuevo (`key`), no al plegar paneles.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [focus?.key]);

  // El halo del dron y la tormenta laten, como en la app. Se cambian
  // propiedades de pintura (sin pasar por React ni volver a subir datos).
  const hasPulse = flights.length > 0 || weather.some((cell) => cell.kind === "storm");
  useEffect(() => {
    const map = mapRef.current?.getMap();
    if (!ready || !map || !hasPulse) return;
    const paint = (t: number) => {
      if (map.getLayer("drone-pulse")) {
        map.setPaintProperty("drone-pulse", "circle-radius", 15 + 21 * t);
        map.setPaintProperty("drone-pulse", "circle-stroke-opacity", 0.7 * (1 - t));
        map.setPaintProperty("drone-pulse", "circle-opacity", 0.12 * (1 - t));
      }
      if (map.getLayer("weather-fill")) {
        const wave = 0.5 + 0.5 * Math.sin(t * Math.PI * 2);
        map.setPaintProperty("weather-fill", "fill-opacity", [
          "match",
          ["get", "kind"],
          "storm",
          0.16 + 0.1 * wave,
          "rain",
          0.14,
          0.08,
        ]);
      }
    };
    if (reducedMotion()) {
      paint(0.35);
      return;
    }
    let frame = 0;
    let last = 0;
    const tick = (time: number) => {
      frame = requestAnimationFrame(tick);
      if (time - last < 50) return;
      last = time;
      // Sale rápido y frena, como `fastOutSlowIn`.
      const p = (time % PULSE_MS) / PULSE_MS;
      paint(1 - (1 - p) ** 3);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [ready, hasPulse]);

  const focusCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: focus
        ? [
            {
              type: "Feature" as const,
              properties: {},
              geometry: { type: "Point" as const, coordinates: [focus.longitude, focus.latitude] },
            },
          ]
        : [],
    }),
    [focus],
  );

  const routeCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: [
        ...routes.previous.flatMap((path) => lineOf(path, "previous")),
        ...lineOf(routes.route?.coordinates, "outbound"),
        ...lineOf(routes.returnRoute?.coordinates, "return"),
      ],
    }),
    [routes],
  );

  // RF-36: las del operador en rosado; las temporales en ámbar, aparte.
  const geofenceCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: geofences.map((geofence) => ({
        type: "Feature" as const,
        properties: { name: geofence.name, temporary: Boolean(geofence.expiresAt) },
        geometry: geofence.polygon,
      })),
    }),
    [geofences],
  );
  const zones = useMemo(() => geofences.filter((geofence) => geofence.expiresAt), [geofences]);

  const weatherCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: weather.flatMap((cell) => {
        const area = {
          type: "Feature" as const,
          properties: { kind: cell.kind, id: cell.id },
          geometry: circlePolygon(cell.latitude, cell.longitude, cell.radiusKm),
        };
        // El viento lleva una flecha hacia donde empuja (de dónde sopla + 180°).
        if (cell.kind !== "wind" || cell.windFromDeg == null) return [area];
        return [
          area,
          {
            type: "Feature" as const,
            properties: { kind: "arrow", id: cell.id, bearing: (cell.windFromDeg + 180) % 360 },
            geometry: { type: "Point" as const, coordinates: [cell.longitude, cell.latitude] },
          },
        ];
      }),
    }),
    [weather],
  );

  const draftCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: draft
        ? [
            {
              type: "Feature" as const,
              properties: { kind: draft.kind },
              geometry: circlePolygon(
                draft.latitude,
                draft.longitude,
                draft.radiusKm,
                draft.kind === "zone" ? 16 : 48,
              ),
            },
          ]
        : [],
    }),
    [draft],
  );

  const onClick = useCallback(
    (event: MapLayerMouseEvent) => {
      if (picking) {
        onPick({ latitude: event.lngLat.lat, longitude: event.lngLat.lng });
        return;
      }
      const orderId = event.features?.[0]?.properties?.orderId as string | undefined;
      onSelect(orderId ? { kind: "flight", id: orderId } : null);
    },
    [onSelect, onPick, picking],
  );

  // Estables: así los marcadores (memo) no se repintan con cada dato del socket.
  const selectHub = useCallback((id: string) => onSelect({ kind: "hub", id }), [onSelect]);
  const selectWeather = useCallback((id: string) => onSelect({ kind: "weather", id }), [onSelect]);
  const selectZone = useCallback((id: string) => onSelect({ kind: "zone", id }), [onSelect]);

  const selectedFlightId = selection?.kind === "flight" ? selection.id : "";
  const geofenceVisibility = showGeofences ? "visible" : "none";
  const darkHubs = useMemo(
    () => new Set(hubs.filter((hub) => hub.powerOutageUntil && Date.parse(hub.powerOutageUntil) > now).map((hub) => hub.id)),
    [hubs, now],
  );

  return (
    <>
      <Map
        ref={mapRef}
        initialViewState={VALLEDUPAR}
        mapStyle={STYLE}
        minZoom={8}
        maxZoom={17}
        attributionControl={{ compact: true }}
        interactiveLayerIds={picking ? [] : ["drones"]}
        onClick={onClick}
        onLoad={onLoad}
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
        cursor={picking ? "crosshair" : hovering ? "pointer" : "grab"}
      >
        {/* Se oculta con `visibility` en vez de desmontar la fuente. */}
        <Source id="geofences" type="geojson" data={geofenceCollection}>
          <Layer
            id="geofences-fill"
            type="fill"
            filter={["!", ["get", "temporary"]]}
            layout={{ visibility: geofenceVisibility }}
            paint={{ "fill-color": COLORS.geofence, "fill-opacity": 0.12 }}
          />
          <Layer
            id="geofences-line"
            type="line"
            filter={["!", ["get", "temporary"]]}
            layout={{ visibility: geofenceVisibility }}
            paint={{
              "line-color": COLORS.geofence,
              "line-width": 1.5,
              "line-opacity": 0.85,
              "line-dasharray": [2, 2],
            }}
          />
          <Layer
            id="zones-fill"
            type="fill"
            filter={["get", "temporary"]}
            paint={{ "fill-color": COLORS.zone, "fill-opacity": 0.14 }}
          />
          <Layer
            id="zones-line"
            type="line"
            filter={["get", "temporary"]}
            paint={{
              "line-color": COLORS.zone,
              "line-width": 2.5,
              "line-opacity": 0.95,
              "line-dasharray": [3, 2],
            }}
          />
        </Source>

        <Source id="weather" type="geojson" data={weatherCollection}>
          <Layer
            id="weather-fill"
            type="fill"
            filter={["!=", ["get", "kind"], "arrow"]}
            paint={{
              "fill-color": [
                "match",
                ["get", "kind"],
                "storm",
                COLORS.storm,
                "rain",
                COLORS.rain,
                COLORS.wind,
              ],
              "fill-opacity": 0.12,
            }}
          />
          <Layer
            id="weather-line"
            type="line"
            filter={["!=", ["get", "kind"], "arrow"]}
            paint={{
              "line-color": [
                "match",
                ["get", "kind"],
                "storm",
                COLORS.storm,
                "rain",
                COLORS.rain,
                COLORS.wind,
              ],
              "line-width": ["match", ["get", "kind"], "storm", 2.5, 1.5],
              "line-opacity": 0.85,
              "line-dasharray": [1.5, 1.5],
            }}
          />
          <Layer
            id="weather-arrow"
            type="symbol"
            filter={["==", ["get", "kind"], "arrow"]}
            layout={{
              "icon-image": ICON_WIND,
              "icon-rotate": ["get", "bearing"],
              "icon-rotation-alignment": "map",
              "icon-offset": [0, -34],
              "icon-allow-overlap": true,
              "icon-ignore-placement": true,
            }}
          />
        </Source>

        {/* CU-38: el evento que se compone, antes de lanzarlo. */}
        <Source id="draft" type="geojson" data={draftCollection}>
          <Layer
            id="draft-fill"
            type="fill"
            paint={{ "fill-color": COLORS.accent, "fill-opacity": 0.1 }}
          />
          <Layer
            id="draft-line"
            type="line"
            paint={{
              "line-color": COLORS.accent,
              "line-width": 2,
              "line-dasharray": [2, 1.5],
            }}
          />
        </Source>

        <Source id="route" type="geojson" data={routeCollection}>
          <Layer
            id="route-previous"
            type="line"
            filter={["==", ["get", "leg"], "previous"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{
              "line-color": COLORS.previous,
              "line-width": 2,
              "line-opacity": 0.7,
              "line-dasharray": [1, 2],
            }}
          />
          <Layer
            id="route-glow"
            type="line"
            filter={["==", ["get", "leg"], "outbound"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{ "line-color": COLORS.outbound, "line-width": 10, "line-opacity": 0.18, "line-blur": 6 }}
          />
          <Layer
            id="route-outbound"
            type="line"
            filter={["==", ["get", "leg"], "outbound"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{ "line-color": COLORS.outbound, "line-width": 3, "line-opacity": 0.95 }}
          />
          <Layer
            id="route-return"
            type="line"
            filter={["==", ["get", "leg"], "return"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{
              "line-color": COLORS.returning,
              "line-width": 3,
              "line-dasharray": [2, 1.5],
            }}
          />
        </Source>

        {/* El punto que la consola pidió mostrar. */}
        <Source id="focus" type="geojson" data={focusCollection}>
          <Layer
            id="focus-ring"
            type="circle"
            paint={{
              "circle-radius": 30,
              "circle-color": COLORS.accent,
              "circle-opacity": 0.08,
              "circle-stroke-color": COLORS.accent,
              "circle-stroke-width": 2,
              "circle-stroke-opacity": 0.9,
            }}
          />
        </Source>

        <Source id="drones" type="geojson" data={EMPTY}>
          {/* El halo que late debajo de cada dron (DroneMarker de la app). */}
          <Layer
            id="drone-pulse"
            type="circle"
            paint={{
              "circle-radius": 20,
              "circle-opacity": 0.1,
              "circle-stroke-width": 1.5,
              "circle-stroke-opacity": 0.5,
              "circle-color": [
                "case",
                ["get", "alert"],
                COLORS.alert,
                ["==", ["get", "leg"], "return"],
                COLORS.returning,
                COLORS.outbound,
              ],
              "circle-stroke-color": [
                "case",
                ["get", "alert"],
                COLORS.alert,
                ["==", ["get", "leg"], "return"],
                COLORS.returning,
                COLORS.outbound,
              ],
            }}
          />
          <Layer
            id="drone-halo"
            type="circle"
            filter={["==", ["get", "orderId"], selectedFlightId]}
            paint={{
              "circle-radius": 31,
              "circle-color": COLORS.accent,
              "circle-opacity": 0.08,
              "circle-stroke-color": COLORS.accent,
              "circle-stroke-width": 2,
              "circle-stroke-opacity": 0.95,
            }}
          />
          <Layer
            id="drones"
            type="symbol"
            layout={{
              "icon-image": [
                "case",
                ["get", "alert"],
                ICON_ALERT,
                ["==", ["get", "leg"], "return"],
                ICON_RETURN,
                ICON_OUTBOUND,
              ],
              "icon-size": ["interpolate", ["linear"], ["zoom"], 9, 0.8, 14, 1],
              "icon-rotate": ["get", "bearing"],
              "icon-rotation-alignment": "map",
              "icon-allow-overlap": true,
              "icon-ignore-placement": true,
            }}
            // RF-34: sin enlace, la posición es estimada y el dron se atenúa.
            paint={{ "icon-opacity": ["case", ["get", "linkLost"], 0.5, 1] }}
          />
        </Source>

        {weather.map((cell) => (
          <WeatherMarker
            key={cell.id}
            cell={cell}
            now={now}
            selected={selection?.kind === "weather" && selection.id === cell.id}
            onSelect={selectWeather}
          />
        ))}
        {zones.map((zone) => (
          <ZoneMarker
            key={zone.id}
            zone={zone}
            now={now}
            selected={selection?.kind === "zone" && selection.id === zone.id}
            onSelect={selectZone}
          />
        ))}
        {landings.map(({ incident, identifier }) => (
          <IncidentMarker key={incident.id} incident={incident} identifier={identifier} now={now} />
        ))}
        {hubs.map((hub) => (
          <HubMarker
            key={hub.id}
            hub={hub}
            dark={darkHubs.has(hub.id)}
            selected={selectedHubId === hub.id}
            onSelect={selectHub}
          />
        ))}
      </Map>

      {/* Acercar, alejar y recentrar: botones de vidrio, como `_MapControls` de la app. */}
      <div
        className={`absolute bottom-28 z-20 hidden flex-col gap-2.5 transition-[right] duration-300 sm:flex ${panelOpen ? "right-[432px]" : "right-4"}`}
      >
        <GlassButton label="Acercar" onClick={() => mapRef.current?.zoomIn()}>
          <PlusIcon size={20} />
        </GlassButton>
        <GlassButton label="Alejar" onClick={() => mapRef.current?.zoomOut()}>
          <MinusIcon size={20} />
        </GlassButton>
        <GlassButton label="Ver todas las centrales" onClick={() => fitHubs(700)}>
          <RecenterIcon size={20} />
        </GlassButton>
      </div>
    </>
  );
}
