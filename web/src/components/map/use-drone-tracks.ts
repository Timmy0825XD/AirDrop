"use client";

import { useEffect, useRef, useState, type RefObject } from "react";
import type { GeoJSONSource } from "maplibre-gl";
import type { MapRef } from "react-map-gl/maplibre";
import { COLORS } from "@/lib/theme";
import type { RadarFlight } from "@/lib/types";
import { BLOCK_FONTS, PIXEL_RATIO, drawDataBlock, type DataBlock } from "./drone-icons";

/** La telemetría llega cada ~2 s: el dron se desliza ese tiempo entre dos puntos. */
const GLIDE_MS = 2_000;
/** ~30 cuadros por segundo bastan para ver el movimiento sin cargar la GPU. */
const FRAME_MS = 33;

type Track = {
  from: [number, number];
  to: [number, number];
  cur: [number, number];
  start: number;
  bearing: number;
};

const hasAlert = (flight: RadarFlight) =>
  Boolean(flight.alerts.battery || flight.alerts.failure || flight.alerts.coldChain);

/** Lo que dice el bloque de datos de un vuelo: su ID y altura, velocidad y batería. */
function dataBlockOf(flight: RadarFlight): DataBlock {
  const part = (value: number | null, unit: string) =>
    value == null ? `— ${unit}` : `${Math.round(value)} ${unit}`;
  const color = hasAlert(flight)
    ? COLORS.alert
    : flight.leg === "return"
      ? COLORS.returning
      : COLORS.outbound;
  const detail = flight.linkLost
    ? "sin enlace · estimada"
    : `${part(flight.altitudeM, "m")} · ${part(flight.speedKmh, "km/h")} · ${part(flight.batteryPercent, "%")}`;
  return { title: flight.identifier, detail, color };
}

export const dataBlockImage = (orderId: string) => `block-${orderId}`;

function bearing(from: [number, number], to: [number, number]): number | null {
  const dx = (to[0] - from[0]) * Math.cos((from[1] * Math.PI) / 180);
  const dy = to[1] - from[1];
  if (Math.abs(dx) < 1e-7 && Math.abs(dy) < 1e-7) return null;
  return ((Math.atan2(dx, dy) * 180) / Math.PI + 360) % 360;
}

/**
 * Mueve los drones en el mapa con un bucle de animación propio: la fuente
 * GeoJSON se actualiza sin pasar por React, así 50 vuelos no repintan el árbol.
 * Cuando ninguno se mueve y no llegó nada nuevo, el bucle no toca el mapa.
 */
export function useDroneTracks(
  mapRef: RefObject<MapRef | null>,
  flights: RadarFlight[],
  ready: boolean,
) {
  const tracks = useRef(new Map<string, Track>());
  const meta = useRef(new Map<string, RadarFlight>());
  /** Lo que dice cada bloque de datos ya dibujado, para no redibujarlo igual. */
  const blocks = useRef(new Map<string, string>());
  /**
   * El lienzo no pide la fuente: si dibuja antes de que cargue, sale la de
   * respaldo. Se espera a Geist Mono y, al llegar, se redibujan los bloques.
   */
  const [fontsReady, setFontsReady] = useState(false);
  useEffect(() => {
    let cancelled = false;
    void Promise.all(BLOCK_FONTS().map((font) => document.fonts.load(font)))
      .catch(() => undefined)
      .then(() => {
        if (cancelled) return;
        blocks.current.clear();
        setFontsReady(true);
      });
    return () => {
      cancelled = true;
    };
  }, []);
  /** Llegaron datos que el mapa aún no dibuja. */
  const changed = useRef(true);

  useEffect(() => {
    const now = performance.now();
    const seen = new Set<string>();
    for (const flight of flights) {
      if (flight.latitude == null || flight.longitude == null) continue;
      seen.add(flight.orderId);
      meta.current.set(flight.orderId, flight);
      const to: [number, number] = [flight.longitude, flight.latitude];
      const track = tracks.current.get(flight.orderId);
      if (!track) {
        tracks.current.set(flight.orderId, { from: to, to, cur: to, start: now, bearing: 0 });
      } else if (track.to[0] !== to[0] || track.to[1] !== to[1]) {
        track.bearing = bearing(track.cur, to) ?? track.bearing;
        track.from = track.cur;
        track.to = to;
        track.start = now;
      }
    }
    for (const id of [...tracks.current.keys()]) {
      if (!seen.has(id)) {
        tracks.current.delete(id);
        meta.current.delete(id);
      }
    }
    // El bloque de datos se redibuja solo cuando cambian sus cifras.
    const map = ready && fontsReady ? mapRef.current?.getMap() : undefined;
    if (map) {
      for (const flight of flights) {
        if (!seen.has(flight.orderId)) continue;
        const block = dataBlockOf(flight);
        const key = `${block.title}|${block.detail}|${block.color}`;
        if (blocks.current.get(flight.orderId) === key) continue;
        blocks.current.set(flight.orderId, key);
        const name = dataBlockImage(flight.orderId);
        if (map.hasImage(name)) map.removeImage(name);
        map.addImage(name, drawDataBlock(block).image, { pixelRatio: PIXEL_RATIO });
      }
      for (const id of [...blocks.current.keys()]) {
        if (seen.has(id)) continue;
        blocks.current.delete(id);
        if (map.hasImage(dataBlockImage(id))) map.removeImage(dataBlockImage(id));
      }
    }
    changed.current = true;
  }, [flights, ready, fontsReady, mapRef]);


  useEffect(() => {
    if (!ready) return;
    let frame = 0;
    let last = 0;
    let moving = true;
    const tick = (time: number) => {
      frame = requestAnimationFrame(tick);
      if (time - last < FRAME_MS) return;
      last = time;
      const source = mapRef.current?.getMap().getSource("drones") as
        | GeoJSONSource
        | undefined;
      if (!source || (!moving && !changed.current)) return;
      changed.current = false;
      moving = false;
      const features = [...tracks.current.entries()].map(([orderId, track]) => {
        const p = Math.min(1, (time - track.start) / GLIDE_MS);
        if (p < 1) moving = true;
        track.cur = [
          track.from[0] + (track.to[0] - track.from[0]) * p,
          track.from[1] + (track.to[1] - track.from[1]) * p,
        ];
        const flight = meta.current.get(orderId);
        return {
          type: "Feature" as const,
          geometry: { type: "Point" as const, coordinates: track.cur },
          properties: {
            orderId,
            bearing: track.bearing,
            leg: flight?.leg ?? "outbound",
            alert: flight ? hasAlert(flight) : false,
            linkLost: flight?.linkLost === true,
            block: blocks.current.has(orderId) ? dataBlockImage(orderId) : "",
          },
        };
      });
      source.setData({ type: "FeatureCollection", features });
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [ready, mapRef]);

  /** Las placas de las centrales también se dibujan en lienzo: esperan la misma fuente. */
  return { fontsReady };
}
