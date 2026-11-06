"use client";

import type { ReactNode } from "react";
import { formatTime } from "@/lib/sim-time";
import type { TimelineEntry, TimelineKind } from "@/lib/types";
import type { ConsoleStatus } from "@/lib/use-console";
import {
  AlertIcon,
  CheckIcon,
  ChevronIcon,
  ClockIcon,
  DroneIcon,
  HubIcon,
  ListIcon,
  PackageIcon,
  RouteIcon,
} from "./icons";
import { Pill } from "./ui";

const ICON: Record<TimelineKind, (size: number) => ReactNode> = {
  order: (size) => <PackageIcon size={size} />,
  queue: (size) => <HubIcon size={size} />,
  decision: (size) => <CheckIcon size={size} />,
  flight: (size) => <DroneIcon size={size} />,
  delivery: (size) => <PackageIcon size={size} />,
  fallback: (size) => <RouteIcon size={size} />,
  alert: (size) => <AlertIcon size={size} />,
  console: (size) => <ClockIcon size={size} />,
};

const TONE: Record<TimelineEntry["severity"], { text: string; tile: string }> = {
  info: { text: "text-accent", tile: "border-accent/30 bg-accent/10" },
  success: { text: "text-success", tile: "border-success/30 bg-success/10" },
  warning: { text: "text-warning", tile: "border-warning/30 bg-warning/10" },
  danger: { text: "text-danger", tile: "border-danger/35 bg-danger/12" },
};

type Props = {
  open: boolean;
  status: ConsoleStatus;
  offMessage: string | null;
  entries: TimelineEntry[];
  onToggle: () => void;
  onPick: (entry: TimelineEntry) => void;
};

/**
 * RF-39: cada paso del flujo, el más reciente arriba. Tocar uno lleva el mapa
 * a donde pasó (y abre el vuelo si sigue en el aire).
 */
export function TimelinePanel({ open, status, offMessage, entries, onToggle, onPick }: Props) {
  if (!open) {
    return (
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={false}
        className="glass absolute left-3 top-[132px] z-20 flex h-12 items-center gap-2.5 rounded-2xl px-4 text-sm font-semibold text-text transition hover:bg-white/10 active:scale-95 focus-visible:outline-2 focus-visible:outline-accent sm:left-4 sm:top-[96px]"
      >
        <ListIcon size={18} className="text-accent" />
        Línea de tiempo
        {entries.length > 0 && <Pill tone="info">{entries.length}</Pill>}
        <ChevronIcon size={16} className="text-muted" />
      </button>
    );
  }

  return (
    <aside
      aria-label="Línea de tiempo"
      className="glass absolute inset-x-3 bottom-3 top-[96px] z-20 flex flex-col overflow-hidden rounded-[28px] sm:inset-x-auto sm:bottom-4 sm:left-4 sm:w-[380px]"
    >
      <header className="flex items-center gap-3 px-5 pb-3 pt-4">
        <ListIcon size={20} className="text-accent" />
        <h2 className="flex-1 text-lg font-semibold tracking-tight">Línea de tiempo</h2>
        <button
          type="button"
          onClick={onToggle}
          aria-expanded
          aria-label="Plegar la línea de tiempo"
          title="Plegar"
          className="grid size-9 place-items-center rounded-xl border border-glass-border bg-glass text-muted transition hover:text-text active:scale-95 focus-visible:outline-2 focus-visible:outline-accent"
        >
          <ChevronIcon size={16} className="rotate-180" />
        </button>
      </header>
      <div className="h-px bg-glass-border" />

      {status === "off" ? (
        <p className="px-5 py-10 text-center text-[15px] text-muted">
          {offMessage ?? "La consola de simulación está apagada."}
        </p>
      ) : status === "loading" ? (
        <div role="status" className="flex justify-center py-10">
          <span className="size-6 animate-spin rounded-full border-2 border-glass-border border-t-accent motion-reduce:animate-none" />
        </div>
      ) : !entries.length ? (
        <p className="px-5 py-10 text-center text-[15px] leading-relaxed text-muted">
          Todavía no pasa nada. Cuando alguien pida o una central despache, aquí aparece cada paso.
        </p>
      ) : (
        <ol className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-3 py-3">
          {entries.map((entry, index) => (
            <li key={entry.id} className={index === 0 ? "rise-in" : undefined}>
              <EntryRow entry={entry} onPick={onPick} />
            </li>
          ))}
        </ol>
      )}
    </aside>
  );
}

function EntryRow({ entry, onPick }: { entry: TimelineEntry; onPick: (entry: TimelineEntry) => void }) {
  const tone = TONE[entry.severity];
  const pickable = entry.orderId != null || entry.latitude != null;
  const body = (
    <>
      <span
        className={`mt-0.5 grid size-9 shrink-0 place-items-center rounded-xl border ${tone.tile} ${tone.text}`}
      >
        {ICON[entry.kind](17)}
      </span>
      <span className="min-w-0 flex-1">
        <span className="flex items-baseline gap-2">
          <span className="text-[15px] font-semibold leading-snug text-text">{entry.title}</span>
        </span>
        {entry.detail && (
          <span className="mt-0.5 block text-[13px] leading-snug text-muted">{entry.detail}</span>
        )}
        <span className="mt-1 flex items-center gap-2 text-[12px] font-medium tabular-nums text-muted">
          {formatTime(entry.at)}
          {entry.source === "console" && <span className="text-accent">· Consola</span>}
        </span>
      </span>
    </>
  );
  const shell = "flex w-full items-start gap-3 rounded-2xl px-2.5 py-2.5 text-left";
  if (!pickable) return <div className={shell}>{body}</div>;
  return (
    <button
      type="button"
      onClick={() => onPick(entry)}
      className={`${shell} transition hover:bg-white/6 active:scale-[0.99] focus-visible:outline-2 focus-visible:outline-accent`}
    >
      {body}
    </button>
  );
}

