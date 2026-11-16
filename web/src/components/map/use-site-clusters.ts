"use client";

import { useEffect, useMemo, useState, type RefObject } from "react";
import type { MapRef } from "react-map-gl/maplibre";
import Supercluster from "supercluster";
import type { DeliveryPoint, HubSummary } from "@/lib/types";

/** Distancia en px en que dos sitios se juntan: un ícono y su nombre no se pisan. */
const CLUSTER_RADIUS_PX = 56;
/** Desde este zoom se ve cada sitio por separado. */
const CLUSTER_MAX_ZOOM = 13;

type SiteProps = { site: "hub" | "point"; id: string };

export type SiteCluster = {
  id: number;
  longitude: number;
  latitude: number;
  count: number;
  /** Cuántos son nodos o ESE: el globo lo dice. */
  hubs: number;
};

/**
 * Al alejar, las centrales y los puntos que quedan cerca se juntan en un globo
 * con su número, para que los íconos no se encimen. Tocar el globo acerca el
 * mapa hasta que se separan. Lo elegido nunca se agrupa: sigue visible.
 */
export function useSiteClusters(
  mapRef: RefObject<MapRef | null>,
  ready: boolean,
  hubs: HubSummary[],
  points: DeliveryPoint[],
  keepVisible: string | null,
) {
  const index = useMemo(() => {
    const cluster = new Supercluster<SiteProps>({
      radius: CLUSTER_RADIUS_PX,
      maxZoom: CLUSTER_MAX_ZOOM,
    });
    cluster.load([
      ...hubs
        .filter((hub) => hub.id !== keepVisible)
        .map((hub) => feature("hub", hub.id, hub.longitude, hub.latitude)),
      ...points
        .filter((point) => point.id !== keepVisible)
        .map((point) => feature("point", point.id, point.longitude, point.latitude)),
    ]);
    return cluster;
  }, [hubs, points, keepVisible]);

  const [view, setView] = useState<{ zoom: number; bounds: [number, number, number, number] } | null>(
    null,
  );

  useEffect(() => {
    const map = mapRef.current?.getMap();
    if (!ready || !map) return;
    const read = () => {
      const bounds = map.getBounds();
      setView({
        zoom: Math.round(map.getZoom()),
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
    const visiblePoints = new Set<string>(keepVisible ? [keepVisible] : []);
    const clusters: SiteCluster[] = [];
    if (!view) {
      for (const hub of hubs) visibleHubs.add(hub.id);
      for (const point of points) visiblePoints.add(point.id);
      return { clusters, visibleHubs, visiblePoints, expand: () => undefined };
    }
    for (const entry of index.getClusters(view.bounds, view.zoom)) {
      const [longitude, latitude] = entry.geometry.coordinates;
      const props = entry.properties as SiteProps & Supercluster.ClusterProperties;
      if (props.cluster) {
        const leaves = index.getLeaves(props.cluster_id, Infinity);
        clusters.push({
          id: props.cluster_id,
          longitude,
          latitude,
          count: props.point_count,
          hubs: leaves.filter((leaf) => leaf.properties.site === "hub").length,
        });
      } else if (props.site === "hub") {
        visibleHubs.add(props.id);
      } else {
        visiblePoints.add(props.id);
      }
    }
    /** Acerca el mapa hasta que el globo se abre. */
    const expand = (cluster: SiteCluster) => {
      const zoom = Math.min(index.getClusterExpansionZoom(cluster.id), CLUSTER_MAX_ZOOM + 1);
      mapRef.current?.easeTo({ center: [cluster.longitude, cluster.latitude], zoom, duration: 600 });
    };
    return { clusters, visibleHubs, visiblePoints, expand };
  }, [index, view, hubs, points, keepVisible, mapRef]);
}

function feature(site: SiteProps["site"], id: string, longitude: number, latitude: number) {
  return {
    type: "Feature" as const,
    properties: { site, id },
    geometry: { type: "Point" as const, coordinates: [longitude, latitude] },
  };
}
