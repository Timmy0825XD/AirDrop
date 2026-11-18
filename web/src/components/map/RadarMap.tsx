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
import type { FeatureCollection, MultiPolygon, Polygon } from "geojson";
import { circlePolygon } from "@/lib/geo";
import { COLORS } from "@/lib/theme";
import type {
  AirspaceZone,
  Corridor,
  Geofence,
  HubSummary,
  Incident,
  RadarFlight,
  Selection,
  UnidentifiedContact,
  WeatherCell,
  WeatherKind,
} from "@/lib/types";
import { MinusIcon, PlusIcon, RecenterIcon } from "../icons";
import { Legend } from "../Legend";
import { IconButton } from "../ui";
import {
  ICON_ALERT,
  ICON_OUTBOUND,
  ICON_RETURN,
  ICON_WIND,
  PATTERN_HATCH,
  PIXEL_RATIO,
  addDroneIcons,
  drawHubPlate,
  type HubPlate,
} from "./drone-icons";
import { IncidentMarker, WeatherMarker, ZoneMarker } from "./EventMarkers";
import { ClusterMarker } from "./ClusterMarker";
import { HubMarker } from "./HubMarker";
import { useSiteClusters } from "./use-site-clusters";
import { fallbackStyle, loadVectorStyle } from "./vector-style";
import { useDroneTracks } from "./use-drone-tracks";

// El worker lo copia `scripts/copy-maplibre.mjs` a /public antes de dev y build.
if (typeof window !== "undefined") setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

/** La región antes de que lleguen las centrales: de Atánquez a Codazzi. */
const REGION = { longitude: -73.27, latitude: 10.38, zoom: 9.3 };
/** El inspector mide 400 px más su margen: el mapa deja ese espacio al encuadrar. */
const PANEL_PX = 416;

/** Un punto que la consola pide mostrar (un paso de la línea de tiempo o una alerta). */
export type MapFocus = { latitude: number; longitude: number; key: number };

/** El evento que se está componiendo: su centro y su radio, para verlo antes de lanzarlo. */
export type EventDraft = {
  kind: WeatherKind | "zone" | "surge";
  latitude: number;
  longitude: number;
  radiusKm: number;
};

const EMPTY: FeatureCollection = { type: "FeatureCollection", features: [] };

/** Desde este zoom se ven las zonas chicas (CAI, batallón, pistas); antes, solo el aeropuerto. */
const SMALL_ZONES_ZOOM = 11;

const plateImage = (hubId: string) => `plate-${hubId}`;

/** El nombre de la central y lo que importa de ella ahora (B10, RF-36). */
function hubPlateOf(hub: HubSummary, dark: boolean): HubPlate {
  if (dark) return { name: hub.name, detail: "sin energía", detailColor: COLORS.returning };
  const queue = hub.queue ?? 0;
  const parts = [
    hub.fleet.inMission > 0 ? `${hub.fleet.inMission} en vuelo` : null,
    queue > 0 ? `${queue} en cola` : null,
  ].filter(Boolean);
  return {
    name: hub.name,
    detail: parts.length ? parts.join(" · ") : null,
    detailColor: queue > 0 ? COLORS.returning : COLORS.muted,
  };
}

type Props = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  geofences: Geofence[];
  /** RF-43: las zonas legales de la región. */
  airspace: AirspaceZone[];
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
  /** RF-36: los drones no identificados que cruzan ahora. */
  contacts: UnidentifiedContact[];
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

export function RadarMap({
  hubs,
  flights,
  geofences,
  airspace,
  showGeofences,
  selection,
  routes,
  insetLeft,
  panelOpen,
  focus,
  onSelect,
  weather,
  contacts,
  landings,
  now,
  picking,
  draft,
  onPick,
}: Props) {
  const mapRef = useRef<MapRef>(null);
  // El tema se fija al montar: Dashboard vuelve a montar el mapa al cambiarlo.
  const [mapStyle, setMapStyle] = useState<StyleSpecification | null>(null);
  useEffect(() => {
    const theme = COLORS.ground === "#f5f4f1" ? "light" : "dark";
    let cancelled = false;
    loadVectorStyle(theme)
      .catch(() => fallbackStyle(theme))
      .then((style) => {
        if (!cancelled) setMapStyle(style);
      });
    return () => {
      cancelled = true;
    };
  }, []);
  const [ready, setReady] = useState(false);
  const [hovering, setHovering] = useState(false);
  const fitted = useRef(false);

  const { fontsReady } = useDroneTracks(mapRef, flights, ready);
  const darkHubs = useMemo(
    () =>
      new Set(
        hubs
          .filter((hub) => hub.powerOutageUntil && Date.parse(hub.powerOutageUntil) > now)
          .map((hub) => hub.id),
      ),
    [hubs, now],
  );
  /** Lo que dice cada placa ya dibujada, para no redibujarla igual. */
  const plates = useRef(new globalThis.Map<string, string>());

  // El riel de la izquierda se pliega y el mapa cambia de ancho: se reacomoda.
  useEffect(() => {
    const map = mapRef.current?.getMap();
    if (!ready || !map) return;
    const observer = new ResizeObserver(() => map.resize());
    observer.observe(map.getContainer());
    return () => observer.disconnect();
  }, [ready]);

  const onLoad = useCallback(() => {
    const map = mapRef.current?.getMap();
    if (!map) return;
    addDroneIcons(map);
    setReady(true);
  }, []);

  /**
   * Encuadra la red de centrales: al llegar la primera
   * vez y con "Recentrar".
   */
  const fitHubs = useCallback(
    (duration: number) => {
      const map = mapRef.current;
      if (!map || !hubs.length) return;
      const lngs = hubs.map((place) => place.longitude);
      const lats = hubs.map((place) => place.latitude);
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
    if (!ready || !hubs.length) return;
    if (fitted.current) return;
    fitted.current = true;
    fitHubs(0);
  }, [ready, hubs, fitHubs]);

  // Al elegir una central, el mapa la lleva al centro del espacio libre.
  const selectedHubId = selection?.kind === "hub" ? selection.id : null;
  const sites = useSiteClusters(mapRef, ready, hubs, selectedHubId);
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

  // Las placas de las centrales: se redibujan solo cuando cambia lo que dicen.
  useEffect(() => {
    const map = mapRef.current?.getMap();
    if (!ready || !fontsReady || !map) return;
    const seen = new Set<string>();
    for (const hub of hubs) {
      seen.add(hub.id);
      const plate = hubPlateOf(hub, darkHubs.has(hub.id));
      const key = `${plate.name}|${plate.detail}|${plate.detailColor}`;
      if (plates.current.get(hub.id) === key && map.hasImage(plateImage(hub.id))) continue;
      plates.current.set(hub.id, key);
      if (map.hasImage(plateImage(hub.id))) map.removeImage(plateImage(hub.id));
      map.addImage(plateImage(hub.id), drawHubPlate(plate), { pixelRatio: PIXEL_RATIO });
    }
    for (const id of [...plates.current.keys()]) {
      if (seen.has(id)) continue;
      plates.current.delete(id);
      if (map.hasImage(plateImage(id))) map.removeImage(plateImage(id));
    }
  }, [ready, fontsReady, hubs, darkHubs]);

  const plateCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: fontsReady
        ? hubs.filter((hub) => sites.visibleHubs.has(hub.id)).map((hub) => ({
            type: "Feature" as const,
            properties: { plate: plateImage(hub.id), hubId: hub.id },
            geometry: { type: "Point" as const, coordinates: [hub.longitude, hub.latitude] },
          }))
        : [],
    }),
    [hubs, fontsReady, sites.visibleHubs],
  );

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

  // RF-36: las del operador, rayadas en magenta; las temporales en ámbar, aparte.
  const geofenceCollection = useMemo(
    (): FeatureCollection => ({
      type: "FeatureCollection" as const,
      features: geofences.map((geofence) => ({
        type: "Feature" as const,
        properties: { name: geofence.name, temporary: Boolean(geofence.expiresAt) },
        geometry: geofence.polygon as Polygon | MultiPolygon,
      })),
    }),
    [geofences],
  );
  const zones = useMemo(() => geofences.filter((geofence) => geofence.expiresAt), [geofences]);

  // RF-43: la carta legal. Va debajo de todo lo demás.
  const airspaceCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: airspace.map((zone) => ({
        type: "Feature" as const,
        properties: { code: zone.code, kind: zone.kind, small: zone.kind !== "aerodrome" },
        geometry: zone.polygon,
      })),
    }),
    [airspace],
  );

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

  // RF-36: el contacto sin matrícula y su estela desde donde apareció.
  const contactCollection = useMemo(
    () => ({
      type: "FeatureCollection" as const,
      features: contacts.flatMap((contact) => [
        {
          type: "Feature" as const,
          properties: { part: "trail", id: contact.id, near: contact.nearIdentifier != null },
          geometry: {
            type: "LineString" as const,
            coordinates: [
              [contact.from.longitude, contact.from.latitude],
              [contact.longitude, contact.latitude],
            ],
          },
        },
        {
          type: "Feature" as const,
          properties: { part: "dot", id: contact.id, near: contact.nearIdentifier != null },
          geometry: {
            type: "Point" as const,
            coordinates: [contact.longitude, contact.latitude],
          },
        },
      ]),
    }),
    [contacts],
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
      // Lo de más arriba gana: un dron y, debajo, la zona.
      const feature = event.features?.[0];
      const properties = feature?.properties ?? {};
      const layer = feature?.layer?.id;
      if (layer === "drones") onSelect({ kind: "flight", id: properties.orderId as string });
      else if (layer === "contacts") onSelect({ kind: "contact", id: properties.id as string });
      else if (layer === "airspace-fill") {
        onSelect({ kind: "airspace", id: properties.code as string });
      } else onSelect(null);
    },
    [onSelect, onPick, picking],
  );

  // Estables: así los marcadores (memo) no se repintan con cada dato del socket.
  const selectHub = useCallback((id: string) => onSelect({ kind: "hub", id }), [onSelect]);
  const selectWeather = useCallback((id: string) => onSelect({ kind: "weather", id }), [onSelect]);
  const selectZone = useCallback((id: string) => onSelect({ kind: "zone", id }), [onSelect]);

  const selectedFlightId = selection?.kind === "flight" ? selection.id : "";
  const selectedContactId = selection?.kind === "contact" ? selection.id : "";
  const selectedZoneCode = selection?.kind === "airspace" ? selection.id : "";
  const geofenceVisibility = showGeofences ? "visible" : "none";

  // Mientras llega el estilo del mapa, el fondo del tema (sin parpadeo).
  if (!mapStyle) return <div className="absolute inset-0 bg-ground" aria-hidden />;

  return (
    <>
      <Map
        ref={mapRef}
        initialViewState={REGION}
        mapStyle={mapStyle}
        minZoom={8}
        maxZoom={17}
        attributionControl={{ compact: true }}
        interactiveLayerIds={picking ? [] : ["drones", "contacts", "airspace-fill"]}
        onClick={onClick}
        onLoad={onLoad}
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
        cursor={picking ? "crosshair" : hovering ? "pointer" : "grab"}
      >
        {/* RF-43: la carta legal, debajo de las geovallas, el clima y las rutas. */}
        <Source id="airspace" type="geojson" data={airspaceCollection}>
          <Layer
            id="airspace-fill"
            type="fill"
            layout={{ visibility: geofenceVisibility }}
            paint={{
              "fill-color": COLORS.noFly,
              // De lejos, solo el aeropuerto; al acercarse aparecen los CAI y demás.
              "fill-opacity": [
                "interpolate",
                ["linear"],
                ["zoom"],
                SMALL_ZONES_ZOOM - 0.6,
                ["case", ["get", "small"], 0, ["==", ["get", "code"], selectedZoneCode], 0.22, 0.1],
                SMALL_ZONES_ZOOM,
                ["case", ["==", ["get", "code"], selectedZoneCode], 0.32, 0.16],
              ],
            }}
          />
          <Layer
            id="airspace-line"
            type="line"
            layout={{ visibility: geofenceVisibility }}
            paint={{
              "line-color": COLORS.noFly,
              "line-width": ["case", ["==", ["get", "code"], selectedZoneCode], 2.4, 1.3],
              "line-opacity": [
                "interpolate",
                ["linear"],
                ["zoom"],
                SMALL_ZONES_ZOOM - 0.6,
                ["case", ["get", "small"], 0, 0.85],
                SMALL_ZONES_ZOOM,
                0.85,
              ],
              "line-dasharray": ["case", ["get", "small"], ["literal", [1, 0]], ["literal", [3, 2]]],
            }}
          />
        </Source>

        {/* Se oculta con `visibility` en vez de desmontar la fuente. */}
        <Source id="geofences" type="geojson" data={geofenceCollection}>
          <Layer
            id="geofences-fill"
            type="fill"
            filter={["!", ["get", "temporary"]]}
            layout={{ visibility: geofenceVisibility }}
            paint={{ "fill-pattern": PATTERN_HATCH }}
          />
          <Layer
            id="geofences-line"
            type="line"
            filter={["!", ["get", "temporary"]]}
            layout={{ visibility: geofenceVisibility }}
            paint={{ "line-color": COLORS.geofence, "line-width": 1.6, "line-opacity": 0.9 }}
          />
          <Layer
            id="zones-fill"
            type="fill"
            filter={["get", "temporary"]}
            paint={{ "fill-color": COLORS.zone, "fill-opacity": 0.08 }}
          />
          <Layer
            id="zones-line"
            type="line"
            filter={["get", "temporary"]}
            paint={{
              "line-color": COLORS.zone,
              "line-width": 1.8,
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
                "fog",
                COLORS.fog,
                "rain",
                COLORS.rain,
                COLORS.wind,
              ],
              "fill-opacity": ["match", ["get", "kind"], "storm", 0.16, "fog", 0.18, 0.08],
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
                "fog",
                COLORS.fog,
                "rain",
                COLORS.rain,
                COLORS.wind,
              ],
              "line-width": ["match", ["get", "kind"], "storm", 1.8, 1.2],
              "line-opacity": 0.8,
              "line-dasharray": [2, 2],
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
            paint={{ "fill-color": COLORS.accent, "fill-opacity": 0.08 }}
          />
          <Layer
            id="draft-line"
            type="line"
            paint={{
              "line-color": COLORS.accent,
              "line-width": 1.6,
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
            id="route-casing"
            type="line"
            filter={["!=", ["get", "leg"], "previous"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{ "line-color": COLORS.ink, "line-width": 5, "line-opacity": 0.7 }}
          />
          <Layer
            id="route-outbound"
            type="line"
            filter={["==", ["get", "leg"], "outbound"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{ "line-color": COLORS.accent, "line-width": 2.4 }}
          />
          <Layer
            id="route-return"
            type="line"
            filter={["==", ["get", "leg"], "return"]}
            layout={{ "line-cap": "round", "line-join": "round" }}
            paint={{
              "line-color": COLORS.returning,
              "line-width": 2.4,
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
              "circle-radius": 28,
              "circle-opacity": 0,
              "circle-stroke-color": COLORS.accent,
              "circle-stroke-width": 1.6,
            }}
          />
        </Source>

        {/* RF-36: el dron no identificado, en magenta y sin matrícula. */}
        <Source id="contacts" type="geojson" data={contactCollection}>
          <Layer
            id="contact-trail"
            type="line"
            filter={["==", ["get", "part"], "trail"]}
            paint={{
              "line-color": COLORS.contact,
              "line-width": 1.6,
              "line-opacity": 0.7,
              "line-dasharray": [1, 2],
            }}
          />
          {/* Cerca de un corredor propio: un halo rojo. */}
          <Layer
            id="contact-halo"
            type="circle"
            filter={["all", ["==", ["get", "part"], "dot"], ["get", "near"]]}
            paint={{
              "circle-radius": 18,
              "circle-opacity": 0,
              "circle-stroke-color": COLORS.alert,
              "circle-stroke-width": 2,
            }}
          />
          <Layer
            id="contacts"
            type="circle"
            filter={["==", ["get", "part"], "dot"]}
            paint={{
              "circle-radius": 8,
              "circle-color": COLORS.contact,
              "circle-stroke-color": [
                "case",
                ["==", ["get", "id"], selectedContactId],
                COLORS.accent,
                COLORS.ink,
              ],
              "circle-stroke-width": 2,
            }}
          />
        </Source>

        {/* Bajo los drones: si una placa choca con un bloque de datos, la placa se oculta. */}
        <Source id="hub-plates" type="geojson" data={plateCollection}>
          <Layer
            id="hub-plates"
            type="symbol"
            layout={{
              "icon-image": ["get", "plate"],
              "icon-anchor": "top",
              "icon-offset": [0, 24],
              "icon-allow-overlap": false,
              "icon-ignore-placement": false,
              "icon-padding": 4,
              "symbol-sort-key": ["case", ["==", ["get", "hubId"], selectedHubId ?? ""], 0, 1],
            }}
          />
        </Source>

        <Source id="drones" type="geojson" data={EMPTY}>
          {/* El elegido lleva un anillo del color de selección. */}
          <Layer
            id="drone-halo"
            type="circle"
            filter={["==", ["get", "orderId"], selectedFlightId]}
            paint={{
              "circle-radius": 22,
              "circle-opacity": 0,
              "circle-stroke-color": COLORS.accent,
              "circle-stroke-width": 1.8,
            }}
          />
          {/* El bloque de datos: no gira con el dron, se lee siempre igual. */}
          <Layer
            id="drone-blocks"
            type="symbol"
            filter={["!=", ["get", "block"], ""]}
            layout={{
              "icon-image": ["get", "block"],
              "icon-anchor": "bottom-left",
              "icon-offset": [6, -6],
              // Dos bloques que chocan no se enciman: queda el elegido, luego el
              // que tiene alerta; el otro dron sigue visible y se puede tocar.
              "icon-allow-overlap": false,
              "icon-ignore-placement": false,
              "icon-padding": 2,
              "symbol-sort-key": [
                "case",
                ["==", ["get", "orderId"], selectedFlightId],
                0,
                ["get", "alert"],
                1,
                2,
              ],
            }}
            paint={{ "icon-opacity": ["case", ["get", "linkLost"], 0.6, 1] }}
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
              "icon-size": ["interpolate", ["linear"], ["zoom"], 9, 0.85, 14, 1],
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
        {sites.clusters.map((cluster) => (
          <ClusterMarker key={cluster.id} cluster={cluster} onExpand={sites.expand} />
        ))}
        {hubs.filter((hub) => sites.visibleHubs.has(hub.id)).map((hub) => (
          <HubMarker
            key={hub.id}
            hub={hub}
            dark={darkHubs.has(hub.id)}
            selected={selectedHubId === hub.id}
            onSelect={selectHub}
          />
        ))}
      </Map>

      {/* Acercar, alejar, recentrar y la leyenda, en una columna a la derecha. */}
      <div
        className={`absolute bottom-4 z-20 hidden flex-col gap-1.5 transition-[right] duration-200 ease-out sm:flex ${panelOpen ? "right-[424px]" : "right-4"}`}
      >
        <Legend />
        <span className="h-1.5" />
        <IconButton label="Acercar" onClick={() => mapRef.current?.zoomIn()}>
          <PlusIcon size={18} />
        </IconButton>
        <IconButton label="Alejar" onClick={() => mapRef.current?.zoomOut()}>
          <MinusIcon size={18} />
        </IconButton>
        <IconButton label="Ver toda la red" onClick={() => fitHubs(700)}>
          <RecenterIcon size={18} />
        </IconButton>
      </div>
    </>
  );
}
