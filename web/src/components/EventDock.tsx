"use client";

import { useState, type ReactNode } from "react";
import { COMPASS } from "@/lib/geo";
import type { WeatherKind } from "@/lib/types";
import type { EventDraft } from "./map/RadarMap";
import { ArrowRightIcon, CloseIcon, RainIcon, StormIcon, WindIcon, ZoneIcon } from "./icons";
import { Chip, GlassButton, IconTile, PrimaryButton } from "./ui";

export type EventTool = WeatherKind | "zone";

const TOOLS: Array<{ tool: EventTool; label: string; icon: (size: number) => ReactNode }> = [
  { tool: "wind", label: "Viento", icon: (size) => <WindIcon size={size} /> },
  { tool: "rain", label: "Lluvia", icon: (size) => <RainIcon size={size} /> },
  { tool: "storm", label: "Tormenta", icon: (size) => <StormIcon size={size} /> },
  { tool: "zone", label: "Zona temporal", icon: (size) => <ZoneIcon size={size} /> },
];

const COPY: Record<EventTool, { title: string; hint: string }> = {
  wind: {
    title: "Viento",
    hint: "En contra frena al dron y gasta más. Sobre 15 m/s (ráfagas de 20) no se vuela.",
  },
  rain: { title: "Lluvia", hint: "Se vuela con un 10 % más de consumo en crucero." },
  storm: {
    title: "Tormenta",
    hint: "Zona no volable: las rutas la rodean y los drones en el aire cambian de camino.",
  },
  zone: {
    title: "Zona temporal",
    hint: "Una geovalla que vence sola. No puede cubrir una central.",
  },
};

const DURATIONS = [15, 30, 60, 120];

/** Lo que se manda al lanzar: el clima (RF-32) o la geovalla temporal (RF-36). */
export type EventLaunch = {
  tool: EventTool;
  latitude: number;
  longitude: number;
  radiusKm: number;
  durationMin: number;
  windSpeedMs: number;
  windFromDeg: number;
  name: string;
};

/**
 * CU-38: la barra flotante con los eventos que se lanzan sobre el mapa, como
 * la barra de navegación de la app. Uno elegido se pinta con el acento.
 */
export function EventDock({
  tool,
  disabled,
  onTool,
}: {
  tool: EventTool | null;
  disabled: boolean;
  onTool: (tool: EventTool | null) => void;
}) {
  return (
    <nav
      aria-label="Lanzar un evento en el mapa"
      className="glass absolute bottom-4 left-1/2 z-20 hidden h-[72px] -translate-x-1/2 items-center gap-1 rounded-[26px] px-2 md:flex"
    >
      <span className="eyebrow px-3 !text-[10px] leading-tight">
        Lanzar en
        <br />
        el mapa
      </span>
      {TOOLS.map((item) => {
        const active = tool === item.tool;
        return (
          <button
            key={item.tool}
            type="button"
            disabled={disabled}
            aria-pressed={active}
            onClick={() => onTool(active ? null : item.tool)}
            className={`relative flex h-14 min-w-[88px] flex-col items-center justify-center gap-1 rounded-[18px] px-3 text-[12px] font-semibold transition active:scale-95 disabled:opacity-40 focus-visible:outline-2 focus-visible:outline-accent ${
              active ? "bg-accent/14 text-accent" : "text-muted hover:bg-white/6 hover:text-text"
            }`}
          >
            {item.icon(20)}
            {item.label}
            {active && <span className="absolute bottom-1 h-[3px] w-5 rounded-full bg-accent" />}
          </button>
        );
      })}
    </nav>
  );
}

/**
 * La tarjeta que compone el evento: primero se toca el mapa (el centro) y
 * después se ajustan el radio, la duración y, si es viento, su fuerza y de
 * dónde sopla. El círculo se ve en el mapa antes de lanzarlo.
 */
export function EventComposer({
  tool,
  center,
  busy,
  onDraft,
  onLaunch,
  onClose,
}: {
  tool: EventTool;
  center: { latitude: number; longitude: number } | null;
  busy: boolean;
  onDraft: (draft: EventDraft | null) => void;
  onLaunch: (launch: EventLaunch) => void;
  onClose: () => void;
}) {
  const zone = tool === "zone";
  const [radiusKm, setRadius] = useState(zone ? 1 : 3);
  const [durationMin, setDuration] = useState(30);
  const [windSpeedMs, setSpeed] = useState(18);
  const [windFromDeg, setFrom] = useState(45);
  const [name, setName] = useState("Evento aéreo");
  const copy = COPY[tool];
  const tile = TOOLS.find((item) => item.tool === tool) as (typeof TOOLS)[number];

  const changeRadius = (value: number) => {
    setRadius(value);
    if (center) onDraft({ kind: tool, ...center, radiusKm: value });
  };

  return (
    <section
      aria-label={`Lanzar ${copy.title.toLowerCase()}`}
      className="glass rise-in absolute bottom-[100px] left-1/2 z-30 w-[min(480px,calc(100%-1.5rem))] -translate-x-1/2 rounded-[28px] p-5"
    >
      <header className="flex items-start gap-3.5">
        <IconTile tone={tool === "storm" ? "bad" : tool === "zone" ? "warn" : "info"}>
          {tile.icon(24)}
        </IconTile>
        <div className="min-w-0 flex-1">
          <h2 className="text-[22px] font-semibold leading-[1.08] tracking-[-0.03em]">{copy.title}</h2>
          <p className="mt-1 text-[13px] leading-snug text-muted">{copy.hint}</p>
        </div>
        <GlassButton label="Cancelar" onClick={onClose} className="!size-10 !rounded-[13px]">
          <CloseIcon size={16} />
        </GlassButton>
      </header>

      {!center ? (
        <p className="mt-4 rounded-2xl border border-accent/30 bg-accent/10 px-4 py-3 text-[15px] font-medium text-accent">
          Toca el mapa donde va el centro.
        </p>
      ) : (
        <div className="mt-4 space-y-4">
          <Slider
            label="Radio"
            value={radiusKm}
            min={0.3}
            max={zone ? 5 : 15}
            step={0.1}
            unit="km"
            onChange={changeRadius}
          />
          {tool === "wind" && (
            <>
              <Slider
                label="Fuerza"
                value={windSpeedMs}
                min={1}
                max={40}
                step={1}
                unit="m/s"
                warn={windSpeedMs > 15}
                onChange={setSpeed}
              />
              <div>
                <span className="eyebrow">De dónde sopla</span>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {COMPASS.map((point) => (
                    <Chip
                      key={point.deg}
                      selected={windFromDeg === point.deg}
                      onClick={() => setFrom(point.deg)}
                    >
                      {point.short}
                    </Chip>
                  ))}
                </div>
              </div>
            </>
          )}
          {zone && (
            <label className="block">
              <span className="eyebrow">Motivo</span>
              <input
                value={name}
                maxLength={80}
                onChange={(event) => setName(event.target.value)}
                className="mt-2 h-11 w-full rounded-2xl border border-white/9 bg-white/4 px-4 text-[15px] outline-none transition focus:border-accent focus:ring-[1.6px] focus:ring-accent"
              />
            </label>
          )}
          <div>
            <span className="eyebrow">Dura</span>
            <div className="mt-2 flex flex-wrap gap-1.5">
              {DURATIONS.map((minutes) => (
                <Chip
                  key={minutes}
                  selected={durationMin === minutes}
                  onClick={() => setDuration(minutes)}
                >
                  {minutes < 60 ? `${minutes} min` : `${minutes / 60} h`}
                </Chip>
              ))}
            </div>
          </div>
          <PrimaryButton
            busy={busy}
            disabled={zone && !name.trim()}
            className="w-full"
            onClick={() =>
              onLaunch({
                tool,
                ...center,
                radiusKm,
                durationMin,
                windSpeedMs,
                windFromDeg,
                name: name.trim(),
              })
            }
          >
            Lanzar {copy.title.toLowerCase()}
            <ArrowRightIcon size={18} strokeWidth={2.2} />
          </PrimaryButton>
        </div>
      )}
    </section>
  );
}

function Slider({
  label,
  value,
  min,
  max,
  step,
  unit,
  warn,
  onChange,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  unit: string;
  warn?: boolean;
  onChange: (value: number) => void;
}) {
  return (
    <label className="block">
      <span className="flex items-baseline justify-between">
        <span className="eyebrow">{label}</span>
        <span
          className={`text-[22px] font-semibold leading-none tracking-[-0.03em] tabular-nums ${warn ? "text-warning" : "text-text"}`}
        >
          {value.toLocaleString("es-CO", { maximumFractionDigits: 1 })}
          <span className="ml-1 text-sm font-medium tracking-normal text-muted">{unit}</span>
        </span>
      </span>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(event) => onChange(Number(event.target.value))}
        className="mt-2 w-full accent-[var(--accent)]"
      />
    </label>
  );
}
