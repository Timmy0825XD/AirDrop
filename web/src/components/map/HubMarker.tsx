"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { HubSummary } from "@/lib/types";
import { DroneIcon, HubTypeIcon } from "../icons";

type Props = {
  hub: HubSummary;
  selected: boolean;
  onSelect: (id: string) => void;
};

/**
 * La central en el mapa: un mosaico de vidrio con el ícono de su tipo
 * (hospital, farmacia, banco de sangre…), cuántos drones vuelan y su nombre.
 * Elegida, toma el acento en degradado y late.
 */
function HubMarkerView({ hub, selected, onSelect }: Props) {
  const active = hub.status === "active";
  const tile = selected
    ? "bg-accent-gradient text-on-accent border-transparent scale-110 shadow-[0_0_0_4px_var(--accent-glow),0_12px_28px_-8px_var(--accent-glow)]"
    : active
      ? "bg-bar text-accent border-accent/45 shadow-[0_10px_24px_-10px_var(--shadow)]"
      : "bg-bar text-muted border-dashed border-muted/50 opacity-80";
  return (
    <Marker longitude={hub.longitude} latitude={hub.latitude} anchor="center">
      <button
        type="button"
        aria-label={`Central ${hub.name}`}
        aria-pressed={selected}
        onClick={(event) => {
          event.stopPropagation();
          onSelect(hub.id);
        }}
        className="group relative block focus:outline-none"
      >
        {selected && <span className="hub-ping absolute inset-0 rounded-[14px] bg-accent" />}
        <span
          className={`relative grid size-10 place-items-center rounded-[14px] border-[1.5px] backdrop-blur-md transition duration-200 group-hover:scale-110 group-focus-visible:ring-2 group-focus-visible:ring-text ${tile}`}
        >
          <HubTypeIcon type={hub.type} size={22} strokeWidth={2} />
        </span>
        {hub.fleet.inMission > 0 && (
          <span
            title={`${hub.fleet.inMission} en vuelo`}
            className="absolute -right-2.5 -top-2.5 flex h-5 items-center gap-0.5 rounded-full border-2 border-backdrop bg-accent-gradient pl-1 pr-1.5 text-[10px] font-bold tabular-nums text-on-accent"
          >
            <DroneIcon size={10} strokeWidth={2.6} />
            {hub.fleet.inMission}
          </span>
        )}
        {/* A un costado y sin captar clics: no tapa al dron que sale o llega. */}
        <span className="pointer-events-none absolute left-full top-1/2 ml-2.5 max-w-44 -translate-y-1/2 truncate rounded-lg border border-glass-border bg-bar px-2 py-1 text-[11px] font-semibold text-text shadow-lg backdrop-blur-md">
          {hub.name}
        </span>
      </button>
    </Marker>
  );
}

export const HubMarker = memo(HubMarkerView);
