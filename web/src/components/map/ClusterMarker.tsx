"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { SiteCluster } from "./use-site-clusters";

type Props = {
  cluster: SiteCluster;
  onExpand: (cluster: SiteCluster) => void;
};

/**
 * Una píldora que dice cuántos sitios hay juntos ("6 sitios"), para que se
 * entienda sin leyenda. Tocarla acerca el mapa hasta separarlos.
 */
function ClusterMarkerView({ cluster, onExpand }: Props) {
  const label = `${cluster.count} centrales juntas. Acercar`;
  return (
    <Marker longitude={cluster.longitude} latitude={cluster.latitude} anchor="center">
      <button
        type="button"
        aria-label={label}
        onClick={(event) => {
          event.stopPropagation();
          onExpand(cluster);
        }}
        title="Acercar para ver cada sitio"
        className="press flex h-9 items-center gap-1.5 rounded-full border-2 border-accent bg-panel px-3 text-[13px] text-text shadow-[0_0_0_5px_color-mix(in_srgb,var(--accent)_16%,transparent)] hover:shadow-[0_0_0_8px_color-mix(in_srgb,var(--accent)_22%,transparent)] focus-visible:ring-2 focus-visible:ring-accent"
      >
        <span className="figures text-[15px] font-bold">{cluster.count}</span>
        <span className="font-medium text-muted">sitios</span>
      </button>
    </Marker>
  );
}

export const ClusterMarker = memo(ClusterMarkerView);
