"use client";

import { memo, type ReactNode } from "react";
import { Marker } from "react-map-gl/maplibre";
import { polygonCenter } from "@/lib/geo";
import { WEATHER_KIND, minutesLeft } from "@/lib/labels";
import type { Geofence, Incident, WeatherCell } from "@/lib/types";
import { AlertIcon, CollisionIcon, RainIcon, StormIcon, WindIcon, ZoneIcon } from "../icons";

const WEATHER_ICON = {
  wind: (size: number) => <WindIcon size={size} />,
  rain: (size: number) => <RainIcon size={size} />,
  storm: (size: number) => <StormIcon size={size} />,
} as const;

const WEATHER_TONE = {
  wind: "border-info/50 text-info",
  rain: "border-info/50 text-info",
  storm: "border-danger/60 text-danger",
} as const;

/** Chip de vidrio en el mapa: se toca para ver el evento y terminarlo. */
function Chip({
  tone,
  icon,
  title,
  detail,
  selected,
  onClick,
}: {
  tone: string;
  icon: ReactNode;
  title: string;
  detail: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={(event) => {
        event.stopPropagation();
        onClick();
      }}
      aria-pressed={selected}
      className={`flex items-center gap-2 rounded-full border-[1.5px] bg-bar py-1.5 pl-2 pr-3 shadow-[0_8px_20px_-8px_var(--shadow)] backdrop-blur-md transition hover:scale-105 active:scale-95 focus-visible:outline-2 focus-visible:outline-accent ${tone} ${
        selected ? "ring-2 ring-accent ring-offset-2 ring-offset-transparent" : ""
      }`}
    >
      {icon}
      <span className="flex flex-col text-left leading-tight">
        <span className="text-[12px] font-semibold text-text">{title}</span>
        <span className="text-[10px] font-semibold tabular-nums">{detail}</span>
      </span>
    </button>
  );
}

function WeatherMarkerView({
  cell,
  now,
  selected,
  onSelect,
}: {
  cell: WeatherCell;
  now: number;
  selected: boolean;
  onSelect: (id: string) => void;
}) {
  const wind =
    cell.kind === "wind" && cell.windSpeedMs != null ? ` ${Math.round(cell.windSpeedMs)} m/s` : "";
  return (
    <Marker longitude={cell.longitude} latitude={cell.latitude} anchor="center">
      <Chip
        tone={WEATHER_TONE[cell.kind]}
        icon={WEATHER_ICON[cell.kind](18)}
        title={`${WEATHER_KIND[cell.kind]}${wind}`}
        detail={`${minutesLeft(cell.endsAt, now)} min`}
        selected={selected}
        onClick={() => onSelect(cell.id)}
      />
    </Marker>
  );
}

function ZoneMarkerView({
  zone,
  now,
  selected,
  onSelect,
}: {
  zone: Geofence;
  now: number;
  selected: boolean;
  onSelect: (id: string) => void;
}) {
  const center = polygonCenter(zone.polygon.coordinates as number[][][]);
  if (!center || !zone.expiresAt) return null;
  return (
    <Marker longitude={center[0]} latitude={center[1]} anchor="center">
      <Chip
        tone="border-warning/60 text-warning"
        icon={<ZoneIcon size={18} />}
        title={zone.name}
        detail={`Zona temporal · ${minutesLeft(zone.expiresAt, now)} min`}
        selected={selected}
        onClick={() => onSelect(zone.id)}
      />
    </Marker>
  );
}

/**
 * RF-34: un dron que cayó o aterrizó de emergencia fuera de su central y
 * espera el rescate. Se enfoca desde la bandeja de alertas.
 */
function IncidentMarkerView({
  incident,
  identifier,
  now,
}: {
  incident: Incident;
  identifier: string;
  now: number;
}) {
  if (incident.landingLatitude == null || incident.landingLongitude == null) return null;
  const crash = incident.protocol === "crash";
  const waiting = incident.outcome === "grounded" && incident.rescueDueAt;
  return (
    <Marker
      longitude={incident.landingLongitude}
      latitude={incident.landingLatitude}
      anchor="center"
    >
      <span className="relative block">
        <span className="halo-pulse absolute inset-0 rounded-full border-2 border-danger" />
        <span className="relative grid size-11 place-items-center rounded-full border-[1.5px] border-danger bg-bar text-danger shadow-[0_0_16px_rgb(255_143_163/0.55)]">
          {crash ? <CollisionIcon size={20} /> : <AlertIcon size={20} />}
        </span>
        <span className="pointer-events-none absolute left-full top-1/2 ml-3 flex -translate-y-1/2 flex-col whitespace-nowrap rounded-[10px] border border-danger/40 bg-bar px-2.5 py-1 shadow-lg backdrop-blur-md">
          <span className="text-[12px] font-semibold text-text">{identifier}</span>
          <span className="text-[10px] font-semibold tabular-nums text-danger">
            {waiting
              ? `Rescate en ${minutesLeft(incident.rescueDueAt as string, now)} min`
              : crash
                ? "Cayó: choque grave"
                : "Aterrizando de emergencia"}
          </span>
        </span>
      </span>
    </Marker>
  );
}

export const WeatherMarker = memo(WeatherMarkerView);
export const ZoneMarker = memo(ZoneMarkerView);
export const IncidentMarker = memo(IncidentMarkerView);
