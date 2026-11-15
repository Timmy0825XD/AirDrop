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
 * La central en el mapa: un cuadro sólido con el ícono de su tipo si es un
 * nodo, o un círculo más chico si es una ESE (RF-06). Su nombre
 * y sus cifras van en una placa del mapa (`hubPlateOf`), que cede su lugar
 * a los drones. Elegida toma el azul de selección. Sin energía, se apaga en
 * ámbar con el rayo tachado (RF-36).
 */
function HubMarkerView({ hub, dark, selected, onSelect }: Props) {
  const active = hub.status === "active";
  // RF-06: el nodo (tiene drones) es un cuadro; la ESE (solo recibe), un círculo.
  const ese = hub.networkRole === "ese";
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
        aria-label={`${ese ? "ESE" : "Nodo"} ${hub.name}${dark ? ", sin energía" : ""}`}
        aria-pressed={selected}
        onClick={(event) => {
          event.stopPropagation();
          onSelect(hub.id);
        }}
        className="group relative block focus:outline-none"
      >
        <span
          className={`relative grid place-items-center border-[1.5px] bg-panel ${ese ? "size-8 rounded-full" : "size-9 rounded-lg"} transition-[border-color,box-shadow,transform] duration-150 group-active:scale-95 group-focus-visible:ring-2 group-focus-visible:ring-accent ${tile}`}
        >
          {dark ? (
            <PowerOffIcon size={18} />
          ) : (
            <HubTypeIcon type={hub.type} size={ese ? 16 : 18} />
          )}
        </span>
      </button>
    </Marker>
  );
}

export const HubMarker = memo(HubMarkerView);
