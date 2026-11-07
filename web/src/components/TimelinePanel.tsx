"use client";

import { formatTime } from "@/lib/sim-time";
import type { TimelineEntry } from "@/lib/types";
import type { ConsoleStatus } from "@/lib/use-console";
import { ChevronIcon, ListIcon } from "./icons";
import { IconButton } from "./ui";

/** El punto de cada paso: el tono dice si salió bien, si preocupa o si falló. */
const MARK: Record<TimelineEntry["severity"], string> = {
  info: "bg-faint",
  success: "bg-success",
  warning: "bg-warning",
  danger: "bg-danger",
};

export type FleetCounters = { hubs: number; flights: number; available: number };

type Props = {
  open: boolean;
  status: ConsoleStatus;
  offMessage: string | null;
  entries: TimelineEntry[];
  counters: FleetCounters;
  onToggle: () => void;
  onPick: (entry: TimelineEntry) => void;
};

function Counter({ value, label }: { value: number; label: string }) {
  return (
    <div className="px-4 py-3.5 first:pl-5">
      <div className="figures text-[26px] font-medium leading-none">{value}</div>
      <div className="mt-1.5 text-[12px] text-muted">{label}</div>
    </div>
  );
}

/**
 * El riel izquierdo: arriba, el estado de la flota en tres cifras; debajo,
 * RF-39, cada paso del flujo como una bitácora, el más reciente arriba.
 * Tocar un paso lleva el mapa a donde pasó (y abre el vuelo si sigue en el
 * aire). Plegado deja una franja con el botón para abrirlo.
 */
export function TimelinePanel({
  open,
  status,
  offMessage,
  entries,
  counters,
  onToggle,
  onPick,
}: Props) {
  if (!open) {
    return (
      <>
        <div className="hidden w-14 shrink-0 flex-col items-center gap-3 border-r border-line bg-panel py-3 md:flex">
          <IconButton label="Abrir la línea de tiempo" onClick={onToggle}>
            <ListIcon size={18} />
          </IconButton>
          {entries.length > 0 && (
            <span className="figures text-[12px] text-muted">{entries.length}</span>
          )}
        </div>
        <button
          type="button"
          onClick={onToggle}
          className="press surface absolute left-3 top-3 z-20 flex h-10 items-center gap-2 rounded-lg px-3 text-[14px] font-medium md:hidden"
        >
          <ListIcon size={16} className="text-muted" />
          Línea de tiempo
        </button>
      </>
    );
  }

  return (
    <aside
      aria-label="Estado y línea de tiempo"
      className="absolute inset-0 z-30 flex flex-col bg-panel md:static md:z-auto md:w-[360px] md:shrink-0 md:border-r md:border-line"
    >
      <div className="grid grid-cols-3 divide-x divide-line border-b border-line">
        <Counter value={counters.hubs} label="Centrales" />
        <Counter value={counters.flights} label="En vuelo" />
        <Counter value={counters.available} label="Drones libres" />
      </div>

      <header className="flex items-center gap-2 px-5 pb-2 pt-4">
        <h2 className="flex-1 text-[14px] font-semibold">
          Línea de tiempo
          {entries.length > 0 && (
            <span className="figures ml-2 text-[12px] font-normal text-faint">{entries.length}</span>
          )}
        </h2>
        <IconButton label="Plegar la línea de tiempo" onClick={onToggle} className="!size-8">
          <ChevronIcon size={15} className="rotate-180" />
        </IconButton>
      </header>

      {status === "off" ? (
        <p className="px-5 py-8 text-[14px] leading-relaxed text-muted">
          {offMessage ?? "La consola de simulación está apagada."}
        </p>
      ) : status === "loading" ? (
        <ol aria-busy className="space-y-4 px-5 py-4">
          {[0, 1, 2].map((row) => (
            <li key={row} className="grid grid-cols-[60px_1fr] gap-3">
              <span className="h-3 w-12 rounded bg-raised" />
              <span className="space-y-2">
                <span className="block h-3 w-4/5 rounded bg-raised" />
                <span className="block h-3 w-3/5 rounded bg-raised" />
              </span>
            </li>
          ))}
        </ol>
      ) : !entries.length ? (
        <div className="px-5 py-8 text-[14px] leading-relaxed text-muted">
          <p className="text-text">Todavía no pasa nada.</p>
          <p className="mt-1">
            Cuando alguien pida, una central despache o lances un evento, cada paso queda aquí con su
            hora.
          </p>
        </div>
      ) : (
        <ol className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-2 pb-3">
          {entries.map((entry, index) => (
            <li key={entry.id} className={index === 0 ? "enter-up" : undefined}>
              <EntryRow entry={entry} onPick={onPick} />
            </li>
          ))}
        </ol>
      )}
    </aside>
  );
}

function EntryRow({ entry, onPick }: { entry: TimelineEntry; onPick: (entry: TimelineEntry) => void }) {
  const pickable = entry.orderId != null || entry.latitude != null;
  const body = (
    <>
      <span className="pt-px">
        <span className="figures block text-[12px] text-faint">{formatTime(entry.at)}</span>
        {entry.source === "console" && (
          <span className="mt-1 block text-[11px] font-medium text-accent">Consola</span>
        )}
        {entry.source === "chaos" && (
          <span className="mt-1 block text-[11px] font-medium text-danger">Caos</span>
        )}
      </span>
      <span className="min-w-0">
        <span className="flex items-start gap-2">
          <span className={`mt-[7px] size-1.5 shrink-0 rounded-full ${MARK[entry.severity]}`} />
          <span className="text-[14px] font-medium leading-snug text-text">{entry.title}</span>
        </span>
        {entry.detail && (
          <span className="mt-1 block pl-3.5 text-[13px] leading-snug text-muted">{entry.detail}</span>
        )}
      </span>
    </>
  );
  const shell = "grid w-full grid-cols-[64px_1fr] gap-2 rounded-md px-3 py-3 text-left";
  if (!pickable) return <div className={shell}>{body}</div>;
  return (
    <button
      type="button"
      onClick={() => onPick(entry)}
      className={`${shell} transition-colors duration-150 hover:bg-hover`}
    >
      {body}
    </button>
  );
}
