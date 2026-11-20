"use client";

import { useEffect, useMemo, useState, type RefObject } from "react";
import type { MapRef } from "react-map-gl/maplibre";
import Supercluster from "supercluster";
import type { HubSummary } from "@/lib/types";

/**
 * Distancia en px en que dos sitios se juntan. Cada central ocupa el ícono
 * más su etiqueta (~200 px de ancho), así que con menos se encimarían.
 */
const CLUSTER_RADIUS_PX = 90;
/** Desde este zoom se ve cada sitio por separado (la región entera ya se lee). */
const CLUSTER_MAX_ZOOM = 10;

type SiteProps = { site: "hub"; id: string };

export type SiteCluster = {
  id: number;
  longitude: number;
  latitude: number;
  count: number;
};

/**
 * Al alejar, las centrales que quedan cerca se juntan en un globo
 * con su número, para que los íconos no se encimen. Tocar el globo acerca el
 * mapa hasta que se separan. Lo elegido nunca se agrupa: sigue visible.
 */
export function useSiteClusters(
  mapRef: RefObject<MapRef | null>,
  ready: boolean,
  hubs: HubSummary[],
  keepVisible: string | null,
) {
  const index = useMemo(() => {
    const cluster = new Supercluster<SiteProps>({
      radius: CLUSTER_RADIUS_PX,
      maxZoom: CLUSTER_MAX_ZOOM,
    });
    cluster.load(
      hubs
        .filter((hub) => hub.id !== keepVisible)
        .map((hub) => feature("hub", hub.id, hub.longitude, hub.latitude)),
    );
    return cluster;
  }, [hubs, keepVisible]);

  const [view, setView] = useState<{ zoom: number; bounds: [number, number, number, number] } | null>(
    null,
  );

  useEffect(() => {
    const map = mapRef.current?.getMap();
    if (!ready || !map) return;
    const read = () => {
      const bounds = map.getBounds();
      setView({
        // Supercluster agrupa por zoom entero: redondear hacia arriba separaba
        // sitios que en pantalla todavía se encimaban.
        zoom: Math.floor(map.getZoom()),
        bounds: [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()],
      });
    };
    read();
    map.on("moveend", read);
    return () => {
      map.off("moveend", read);
    };
  }, [mapRef, ready]);

  return useMemo(() => {
    const visibleHubs = new Set<string>(keepVisible ? [keepVisible] : []);
    const clusters: SiteCluster[] = [];
    if (!view) {
      for (const hub of hubs) visibleHubs.add(hub.id);
      return { clusters, visibleHubs, expand: () => undefined };
    }
    for (const entry of index.getClusters(view.bounds, view.zoom)) {
      const [longitude, latitude] = entry.geometry.coordinates;
      const props = entry.properties as SiteProps & Supercluster.ClusterProperties;
      if (props.cluster) {
        clusters.push({ id: props.cluster_id, longitude, latitude, count: props.point_count });
      } else {
        visibleHubs.add(props.id);
      }
    }
    /** Acerca el mapa hasta que el globo se abre. */
    const expand = (cluster: SiteCluster) => {
      const zoom = Math.min(index.getClusterExpansionZoom(cluster.id), CLUSTER_MAX_ZOOM + 1);
      mapRef.current?.easeTo({ center: [cluster.longitude, cluster.latitude], zoom, duration: 600 });
    };
    return { clusters, visibleHubs, expand };
  }, [index, view, hubs, keepVisible, mapRef]);
}

function feature(site: SiteProps["site"], id: string, longitude: number, latitude: number) {
  return {
    type: "Feature" as const,
    properties: { site, id },
    geometry: { type: "Point" as const, coordinates: [longitude, latitude] },
  };
}
