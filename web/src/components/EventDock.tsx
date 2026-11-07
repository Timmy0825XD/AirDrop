"use client";

import { useState, type ReactNode } from "react";
import { COMPASS } from "@/lib/geo";
import type { WeatherKind } from "@/lib/types";
import type { EventDraft } from "./map/RadarMap";
import {
  ArrowRightIcon,
  CloseIcon,
  MinusIcon,
  PlusIcon,
  RainIcon,
  StormIcon,
  SurgeIcon,
  WindIcon,
  ZoneIcon,
} from "./icons";
import { Button, Chip, IconButton } from "./ui";

export type EventTool = WeatherKind | "zone" | "surge";

const TOOLS: Array<{ tool: EventTool; label: string; icon: (size: number) => ReactNode }> = [
  { tool: "wind", label: "Viento", icon: (size) => <WindIcon size={size} /> },
  { tool: "rain", label: "Lluvia", icon: (size) => <RainIcon size={size} /> },
  { tool: "storm", label: "Tormenta", icon: (size) => <StormIcon size={size} /> },
  { tool: "zone", label: "Zona temporal", icon: (size) => <ZoneIcon size={size} /> },
  { tool: "surge", label: "Pico", icon: (size) => <SurgeIcon size={size} /> },
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
  surge: {
    title: "Pico de urgencias",
    hint: "Urgencias seguidas de solicitantes simulados dentro del círculo. El motor las reparte entre las centrales.",
  },
};

/** RF-36: de 2 a 15 urgencias, como acepta el backend. */
const SURGE_MIN = 2;
const SURGE_MAX = 15;

const DURATIONS = [15, 30, 60, 120];

/**
 * Lo que se manda al lanzar: el clima (RF-32), la geovalla temporal o el
 * pico de urgencias (RF-36).
 */
export type EventLaunch = {
  tool: EventTool;
  latitude: number;
  longitude: number;
  radiusKm: number;
  durationMin: number;
  windSpeedMs: number;
  windFromDeg: number;
  name: string;
  /** Pico: cuántas urgencias. */
  count: number;
};

/**
 * CU-38: la barra con los eventos que se lanzan sobre el mapa. El elegido se
 * marca con el azul de selección.
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
      className="surface absolute bottom-4 left-1/2 z-20 hidden -translate-x-1/2 items-center gap-0.5 rounded-xl p-1 md:flex"
    >
      {TOOLS.map((item) => {
        const active = tool === item.tool;
        return (
          <button
            key={item.tool}
            type="button"
            disabled={disabled}
            aria-pressed={active}
            onClick={() => onTool(active ? null : item.tool)}
            className={`press flex h-14 min-w-[84px] flex-col items-center justify-center gap-1 rounded-lg px-3 text-[12.5px] font-medium disabled:opacity-40 ${
              active ? "bg-accent/14 text-accent" : "text-muted hover:bg-hover hover:text-text"
            }`}
          >
            {item.icon(19)}
            {item.label}
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
  const surge = tool === "surge";
  const [radiusKm, setRadius] = useState(zone || surge ? 1 : 3);
  const [count, setCount] = useState(5);
  const [durationMin, setDuration] = useState(30);
  const [windSpeedMs, setSpeed] = useState(18);
  const [windFromDeg, setFrom] = useState(45);
  const [name, setName] = useState("Evento aéreo");
  const copy = COPY[tool];

  const changeRadius = (value: number) => {
    setRadius(value);
    if (center) onDraft({ kind: tool, ...center, radiusKm: value });
  };

  return (
    <section
      aria-label={`Lanzar ${copy.title.toLowerCase()}`}
      className="surface enter-up absolute bottom-[92px] left-1/2 z-30 w-[min(440px,calc(100%-1.5rem))] -translate-x-1/2 rounded-xl"
    >
      <header className="flex items-start gap-3 px-5 pb-4 pt-4">
        <div className="min-w-0 flex-1">
          <h2 className="text-[17px] font-semibold tracking-[-0.01em]">{copy.title}</h2>
          <p className="mt-1 text-[13px] leading-snug text-muted">{copy.hint}</p>
        </div>
        <IconButton label="Cancelar" onClick={onClose} className="!size-8">
          <CloseIcon size={15} />
        </IconButton>
      </header>

      {!center ? (
        <p className="mx-5 mb-5 flex items-center gap-2.5 rounded-lg border border-dashed border-accent/50 px-4 py-3 text-[14px] text-accent">
          <span className="size-2 rounded-full bg-accent" />
          Toca el mapa donde va el centro.
        </p>
      ) : (
        <div className="space-y-5 border-t border-line px-5 pb-5 pt-4">
          <Slider
            label="Radio"
            value={radiusKm}
            min={0.3}
            max={zone ? 5 : surge ? 3 : 15}
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
                <span className="text-[13px] text-muted">De dónde sopla</span>
                <div className="mt-2 grid grid-cols-8 gap-1">
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
              <span className="text-[13px] text-muted">Motivo</span>
              <input
                value={name}
                maxLength={80}
                onChange={(event) => setName(event.target.value)}
                className="mt-2 h-10 w-full rounded-lg border border-line bg-ground px-3 text-[14px] outline-none transition-[border-color] focus:border-accent"
              />
            </label>
          )}
          {surge ? (
            <Counter
              label="Urgencias"
              value={count}
              min={SURGE_MIN}
              max={SURGE_MAX}
              onChange={setCount}
            />
          ) : (
            <div>
              <span className="text-[13px] text-muted">Dura</span>
              <div className="mt-2 grid grid-cols-4 gap-1">
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
          )}
          <Button
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
                count,
              })
            }
          >
            {surge ? `Lanzar ${count} urgencias` : `Lanzar ${copy.title.toLowerCase()}`}
            <ArrowRightIcon size={16} />
          </Button>
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
        <span className="text-[13px] text-muted">{label}</span>
        <span className={`figures text-[18px] font-medium leading-none ${warn ? "text-warning" : "text-text"}`}>
          {value.toLocaleString("es-CO", { maximumFractionDigits: 1 })}
          <span className="ml-1 font-sans text-[12px] font-normal text-muted">{unit}</span>
        </span>
      </span>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(event) => onChange(Number(event.target.value))}
        className="mt-2.5 w-full accent-[var(--accent)]"
      />
    </label>
  );
}

/**
 * Un número entero con − y +, y también escribible: el administrador elige
 * cuántas urgencias (máximo 15).
 */
function Counter({
  label,
  value,
  min,
  max,
  onChange,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
}) {
  const clamp = (next: number) => Math.min(max, Math.max(min, Math.round(next)));
  return (
    <div>
      <span className="flex items-baseline justify-between">
        <span className="text-[13px] text-muted">{label}</span>
        <span className="text-[12px] text-faint">
          De {min} a {max}
        </span>
      </span>
      <div className="mt-2 flex items-center gap-1.5">
        <IconButton label="Una menos" disabled={value <= min} onClick={() => onChange(clamp(value - 1))}>
          <MinusIcon size={16} />
        </IconButton>
        <input
          type="number"
          inputMode="numeric"
          min={min}
          max={max}
          value={value}
          aria-label={label}
          onChange={(event) => {
            const next = Number(event.target.value);
            if (Number.isFinite(next)) onChange(clamp(next));
          }}
          className="figures h-10 w-full rounded-lg border border-line bg-ground px-3 text-center text-[18px] font-medium outline-none transition-[border-color] focus:border-accent"
        />
        <IconButton label="Una más" disabled={value >= max} onClick={() => onChange(clamp(value + 1))}>
          <PlusIcon size={16} />
        </IconButton>
      </div>
    </div>
  );
}
