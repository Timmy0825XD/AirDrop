"use client";

import { memo } from "react";
import { Marker } from "react-map-gl/maplibre";
import type { HubSummary } from "@/lib/types";
import { DroneIcon, HubTypeIcon, ListIcon, PowerOffIcon } from "../icons";

type Props = {
  hub: HubSummary;
  /** RF-36: la central está sin energía ahora. */
  dark: boolean;
  selected: boolean;
  onSelect: (id: string) => void;
};

/**
 * La central en el mapa, como `HubMarker` de la app: un cuadro de vidrio con
 * el borde y el brillo del acento, y el ícono de su tipo. Lleva cuántos
 * drones vuelan, cuántos pedidos esperan en su cola (B10) y su nombre.
 * Elegida, toma el acento en degradado y late. Sin energía, se apaga en
 * ámbar con un rayo tachado (RF-36).
 */
function HubMarkerView({ hub, dark, selected, onSelect }: Props) {
  const active = hub.status === "active";
  const tile = selected
    ? "bg-accent-gradient text-on-accent border-transparent scale-110 shadow-[0_0_0_4px_var(--accent-glow),0_12px_28px_-8px_var(--accent-glow)]"
    : dark
      ? "bg-bar text-warning border-warning border-dashed shadow-[0_0_14px_rgb(251_191_106/0.35)]"
      : active
        ? "bg-bar text-accent border-accent shadow-[0_0_14px_rgb(79_195_201/0.35)]"
        : "bg-bar text-muted border-dashed border-muted/50 opacity-80";
  const queue = hub.queue ?? 0;
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
        {selected && <span className="hub-ping absolute inset-0 rounded-[12px] bg-accent" />}
        <span
          className={`relative grid size-11 place-items-center rounded-[12px] border-[1.5px] backdrop-blur-md transition duration-200 group-hover:scale-110 group-focus-visible:ring-2 group-focus-visible:ring-text ${tile}`}
        >
          {dark && !selected ? (
            <PowerOffIcon size={22} strokeWidth={2} />
          ) : (
            <HubTypeIcon type={hub.type} size={22} strokeWidth={2} />
          )}
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
        {queue > 0 && (
          <span
            title={`${queue} ${queue === 1 ? "pedido espera" : "pedidos esperan"} en su cola`}
            className="absolute -bottom-2.5 -right-2.5 flex h-5 items-center gap-0.5 rounded-full border-2 border-backdrop bg-warning pl-1 pr-1.5 text-[10px] font-bold tabular-nums text-on-accent"
          >
            <ListIcon size={10} strokeWidth={2.8} />
            {queue}
          </span>
        )}
        {/* A un costado y sin captar clics: no tapa al dron que sale o llega. */}
        <span className="pointer-events-none absolute left-full top-1/2 ml-3 flex max-w-52 -translate-y-1/2 flex-col rounded-[10px] border border-glass-border bg-bar px-2.5 py-1 text-left shadow-lg backdrop-blur-md">
          <span className="truncate text-[12px] font-semibold text-text">{hub.name}</span>
          {dark && <span className="text-[10px] font-semibold text-warning">Sin energía</span>}
        </span>
      </button>
    </Marker>
  );
}

export const HubMarker = memo(HubMarkerView);
