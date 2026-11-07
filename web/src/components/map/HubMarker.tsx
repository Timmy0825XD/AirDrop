"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { HubSummary } from "@/lib/types";
import { HubTypeIcon, PowerOffIcon } from "../icons";

type Props = {
  hub: HubSummary;
  /** RF-36: la central está sin energía ahora. */
  dark: boolean;
  selected: boolean;
  onSelect: (id: string) => void;
};

/**
 * La central en el mapa: un cuadro sólido con el ícono de su tipo. Su nombre
 * y sus cifras van en una placa del mapa (`hubPlateOf`), que cede su lugar
 * a los drones. Elegida toma el azul de selección. Sin energía, se apaga en
 * ámbar con el rayo tachado (RF-36).
 */
function HubMarkerView({ hub, dark, selected, onSelect }: Props) {
  const active = hub.status === "active";
  const tile = selected
    ? "border-accent text-accent shadow-[0_0_0_3px_rgb(122_167_255/0.25)]"
    : dark
      ? "border-warning border-dashed text-warning"
      : active
        ? "border-line-strong text-text group-hover:border-muted"
        : "border-line border-dashed text-faint";
  return (
    <Marker longitude={hub.longitude} latitude={hub.latitude} anchor="center">
      <button
        type="button"
        aria-label={`Central ${hub.name}${dark ? ", sin energía" : ""}`}
        aria-pressed={selected}
        onClick={(event) => {
          event.stopPropagation();
          onSelect(hub.id);
        }}
        className="group relative block focus:outline-none"
      >
        <span
          className={`relative grid size-9 place-items-center rounded-lg border-[1.5px] bg-panel transition-[border-color,box-shadow,transform] duration-150 group-active:scale-95 group-focus-visible:ring-2 group-focus-visible:ring-accent ${tile}`}
        >
          {dark ? (
            <PowerOffIcon size={18} />
          ) : (
            <HubTypeIcon type={hub.type} size={18} />
          )}
        </span>
      </button>
    </Marker>
  );
}

export const HubMarker = memo(HubMarkerView);
