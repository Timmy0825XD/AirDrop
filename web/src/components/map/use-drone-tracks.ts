"use client";

import { useEffect, useRef, type RefObject } from "react";
import type { GeoJSONSource } from "maplibre-gl";
import type { MapRef } from "react-map-gl/maplibre";
import type { RadarFlight } from "@/lib/types";

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
    changed.current = true;
  }, [flights]);

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
        const alerts = flight?.alerts;
        return {
          type: "Feature" as const,
          geometry: { type: "Point" as const, coordinates: track.cur },
          properties: {
            orderId,
            bearing: track.bearing,
            leg: flight?.leg ?? "outbound",
            alert: Boolean(alerts && (alerts.battery || alerts.failure || alerts.coldChain)),
          },
        };
      });
      source.setData({ type: "FeatureCollection", features });
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [ready, mapRef]);
}
