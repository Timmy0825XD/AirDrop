"use client";

import "maplibre-gl/dist/maplibre-gl.css";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Map, {
  Layer,
  NavigationControl,
  Source,
  type MapLayerMouseEvent,
  type MapRef,
} from "react-map-gl/maplibre";
import { setWorkerUrl, type StyleSpecification } from "maplibre-gl";
import { COLORS } from "@/lib/theme";
import type {
  Corridor,
  Geofence,
  HubSummary,
  RadarFlight,
  Selection,
} from "@/lib/types";
import {
  ICON_ALERT,
  ICON_OUTBOUND,
  ICON_RETURN,
  addDroneIcons,
} from "./drone-icons";
import { HubMarker } from "./HubMarker";
import { useDroneTracks } from "./use-drone-tracks";

// El worker lo copia `scripts/copy-maplibre.mjs` a /public antes de dev y build.
if (typeof window !== "undefined") setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

const VALLEDUPAR = { longitude: -73.2532, latitude: 10.4631, zoom: 11 };
/** El panel lateral mide 400 px más su margen: el mapa deja ese espacio al encuadrar. */
const PANEL_PX = 416;

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
  routes: { route: Corridor | null; returnRoute: Corridor | null };
  onSelect: (selection: Selection) => void;
};

function lineOf(corridor: Corridor | null, leg: string) {
  return corridor && corridor.coordinates.length >= 2
    ? [
        {
          type: "Feature" as const,
          properties: { leg },
          geometry: { type: "LineString" as const, coordinates: corridor.coordinates },
        },
      ]
    : [];
}

export function RadarMap({
  hubs,
  flights,
  geofences,
  showGeofences,
  selection,
  routes,
  onSelect,
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

  // Encuadra todas las centrales la primera vez que llegan.
  useEffect(() => {
    const map = mapRef.current;
    if (!ready || fitted.current || !hubs.length || !map) return;
    fitted.current = true;
    const lngs = hubs.map((hub) => hub.longitude);
    const lats = hubs.map((hub) => hub.latitude);
    map.fitBounds(
      [
        [Math.min(...lngs), Math.min(...lats)],
        [Math.max(...lngs), Math.max(...lats)],
      ],
      {
        padding: { top: 140, bottom: 100, left: 80, right: PANEL_PX + 40 },
        maxZoom: 13,
        duration: 0,
      },
    );
  }, [ready, hubs]);

  // Al elegir una central, el mapa la lleva al centro del espacio libre.
  const selectedHubId = selection?.kind === "hub" ? selection.id : null;
  useEffect(() => {
    const hub = hubs.find((row) => row.id === selectedHubId);
    if (!hub) return;
    mapRef.current?.easeTo({
      center: [hub.longitude, hub.latitude],
      padding: { right: PANEL_PX },
      duration: 600,
    });
  }, [selectedHubId, hubs]);

  const routeCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: [
        ...lineOf(routes.route, "outbound"),
        ...lineOf(routes.returnRoute, "return"),
      ],
    }),
    [routes],
  );

  const geofenceCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: geofences.map((geofence) => ({
        type: "Feature" as const,
        properties: { name: geofence.name },
        geometry: geofence.polygon,
      })),
    }),
    [geofences],
  );

  const onClick = useCallback(
    (event: MapLayerMouseEvent) => {
      const orderId = event.features?.[0]?.properties?.orderId as string | undefined;
      onSelect(orderId ? { kind: "flight", id: orderId } : null);
    },
    [onSelect],
  );

  // Estable: así `HubMarker` (memo) no se repinta con cada dato del socket.
  const selectHub = useCallback((id: string) => onSelect({ kind: "hub", id }), [onSelect]);

  const selectedFlightId = selection?.kind === "flight" ? selection.id : "";
  const geofenceVisibility = showGeofences ? "visible" : "none";

  return (
    <Map
      ref={mapRef}
      initialViewState={VALLEDUPAR}
      mapStyle={STYLE}
      minZoom={8}
      maxZoom={17}
      attributionControl={{ compact: true }}
      interactiveLayerIds={["drones"]}
      onClick={onClick}
      onLoad={onLoad}
      onMouseEnter={() => setHovering(true)}
      onMouseLeave={() => setHovering(false)}
      cursor={hovering ? "pointer" : "grab"}
    >
      <NavigationControl position="bottom-left" showCompass={false} />

      {/* Se oculta con `visibility` en vez de desmontar la fuente. */}
      <Source id="geofences" type="geojson" data={geofenceCollection}>
        <Layer
          id="geofences-fill"
          type="fill"
          layout={{ visibility: geofenceVisibility }}
          paint={{ "fill-color": COLORS.geofence, "fill-opacity": 0.12 }}
        />
        <Layer
          id="geofences-line"
          type="line"
          layout={{ visibility: geofenceVisibility }}
          paint={{
            "line-color": COLORS.geofence,
            "line-width": 1.5,
            "line-opacity": 0.85,
            "line-dasharray": [2, 2],
          }}
        />
      </Source>

      <Source id="route" type="geojson" data={routeCollection}>
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

      <Source id="drones" type="geojson" data={EMPTY}>
        <Layer
          id="drone-glow"
          type="circle"
          paint={{
            "circle-radius": 22,
            "circle-blur": 0.9,
            "circle-opacity": 0.4,
            "circle-color": [
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
            "circle-radius": 28,
            "circle-color": COLORS.accent,
            "circle-opacity": 0.1,
            "circle-stroke-color": COLORS.accent,
            "circle-stroke-width": 1.5,
            "circle-stroke-opacity": 0.9,
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
            "icon-size": ["interpolate", ["linear"], ["zoom"], 9, 0.7, 14, 1],
            "icon-rotate": ["get", "bearing"],
            "icon-rotation-alignment": "map",
            "icon-allow-overlap": true,
            "icon-ignore-placement": true,
          }}
        />
      </Source>

      {hubs.map((hub) => (
        <HubMarker
          key={hub.id}
          hub={hub}
          selected={selectedHubId === hub.id}
          onSelect={selectHub}
        />
      ))}
    </Map>
  );
}
