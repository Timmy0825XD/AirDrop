"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { HubSummary } from "@/lib/types";

type Props = {
  hub: HubSummary;
  selected: boolean;
  onSelect: (id: string) => void;
};

/** La central en el mapa: ícono de cruz médica y cuántos drones vuelan. */
function HubMarkerView({ hub, selected, onSelect }: Props) {
  const active = hub.status === "active";
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
        <span
          className={`grid size-9 place-items-center rounded-full border-2 shadow-lg transition-transform group-hover:scale-110 group-focus-visible:ring-2 group-focus-visible:ring-white ${
            active
              ? "border-hub bg-ink text-hub"
              : "border-hub-off bg-ink text-hub-off"
          } ${selected ? "scale-125 ring-4 ring-hub/40" : ""}`}
        >
          <svg viewBox="0 0 24 24" className="size-5" fill="currentColor" aria-hidden>
            <path d="M10 3h4v7h7v4h-7v7h-4v-7H3v-4h7z" />
          </svg>
        </span>
        {hub.fleet.inMission > 0 && (
          <span className="absolute -right-2 -top-2 grid min-w-5 place-items-center rounded-full bg-outbound px-1 text-[10px] font-bold text-ink">
            {hub.fleet.inMission}
          </span>
        )}
        {/* A un costado y sin captar clics: no tapa al dron que sale o llega. */}
        <span className="pointer-events-none absolute left-full top-1/2 ml-2 max-w-40 -translate-y-1/2 truncate rounded bg-ink/75 px-1.5 py-0.5 text-[11px] font-medium text-white backdrop-blur">
          {hub.name}
        </span>
      </button>
    </Marker>
  );
}

export const HubMarker = memo(HubMarkerView);
