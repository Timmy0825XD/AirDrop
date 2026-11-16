"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { SiteCluster } from "./use-site-clusters";

type Props = {
  cluster: SiteCluster;
  onExpand: (cluster: SiteCluster) => void;
};

/** Un globo con cuántos sitios hay juntos. Tocarlo acerca el mapa hasta separarlos. */
function ClusterMarkerView({ cluster, onExpand }: Props) {
  const size = cluster.count >= 10 ? "size-12 text-[15px]" : "size-10 text-[14px]";
  const label =
    cluster.hubs > 0
      ? `${cluster.count} sitios juntos, ${cluster.hubs} centrales. Acercar`
      : `${cluster.count} puntos de entrega juntos. Acercar`;
  return (
    <Marker longitude={cluster.longitude} latitude={cluster.latitude} anchor="center">
      <button
        type="button"
        aria-label={label}
        onClick={(event) => {
          event.stopPropagation();
          onExpand(cluster);
        }}
        className={`press grid place-items-center rounded-full border-2 border-accent bg-panel font-bold text-text shadow-[0_0_0_6px_color-mix(in_srgb,var(--accent)_18%,transparent)] hover:shadow-[0_0_0_9px_color-mix(in_srgb,var(--accent)_22%,transparent)] focus-visible:ring-2 focus-visible:ring-accent ${size}`}
      >
        <span className="figures">{cluster.count}</span>
      </button>
    </Marker>
  );
}

export const ClusterMarker = memo(ClusterMarkerView);
