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

const VALLEDUPAR ={ longitude: -73.2532, latitude: 10.4631, zoom: 11 };
/** El panel lateral mide 420 px: el mapa deja ese espacio al encuadrar. */
const PANEL_PX = 420;

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
  layers: [
    { id: "base", type: "raster", source: "base" },
    { id: "labels", type: "raster", source: "labels" },
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

  const selectedFlightId = selection?.kind === "flight" ? selection.id : "";

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
      cursor="grab"
    >
      <NavigationControl position="bottom-left" showCompass={false} />

      {showGeofences && (
        <Source id="geofences" type="geojson" data={geofenceCollection}>
          <Layer
            id="geofences-fill"
            type="fill"
            paint={{ "fill-color": COLORS.geofence, "fill-opacity": 0.16 }}
          />
          <Layer
            id="geofences-line"
            type="line"
            paint={{ "line-color": COLORS.geofence, "line-width": 1.5, "line-dasharray": [2, 2] }}
          />
        </Source>
      )}

      <Source id="route" type="geojson" data={routeCollection}>
        <Layer
          id="route-outbound"
          type="line"
          filter={["==", ["get", "leg"], "outbound"]}
          layout={{ "line-cap": "round", "line-join": "round" }}
          paint={{ "line-color": COLORS.outbound, "line-width": 3, "line-opacity": 0.9 }}
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
          id="drone-halo"
          type="circle"
          filter={["==", ["get", "orderId"], selectedFlightId]}
          paint={{
            "circle-radius": 24,
            "circle-color": COLORS.outbound,
            "circle-opacity": 0.14,
            "circle-stroke-color": COLORS.outbound,
            "circle-stroke-width": 2,
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
            "icon-size": 0.55,
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
          onSelect={(id) => onSelect({ kind: "hub", id })}
        />
      ))}
    </Map>
  );
}
