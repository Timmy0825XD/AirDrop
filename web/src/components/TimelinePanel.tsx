"use client";

import { useMemo, useState } from "react";
import { formatTime } from "@/lib/sim-time";
import type { TimelineCategory, TimelineEntry } from "@/lib/types";
import type { ConsoleStatus } from "@/lib/use-console";
import { ChevronIcon, ListIcon } from "./icons";
import { IconButton } from "./ui";

/** El punto de cada paso: el tono dice si salió bien, si preocupa o si falló. */
const MARK: Record<TimelineEntry["severity"], string> = {
  info: "bg-info",
  success: "bg-success",
  warning: "bg-warning",
  danger: "bg-danger",
};

type Filter = "all" | Exclude<TimelineCategory, "console">;

/** Los filtros de la línea de tiempo; lo técnico (reloj, actores) no se muestra. */
const FILTERS: Array<{ id: Filter; label: string }> = [
  { id: "all", label: "Todo" },
  { id: "order", label: "Pedidos" },
  { id: "flight", label: "Vuelos" },
  { id: "incident", label: "Incidentes" },
  { id: "environment", label: "Entorno" },
];

/** La categoría de un paso; las entradas de antes de RF-39 se deducen de su tipo. */
function categoryOf(entry: TimelineEntry): TimelineCategory {
  if (entry.category) return entry.category;
  switch (entry.kind) {
    case "flight":
    case "delivery":
      return "flight";
    case "alert":
      return "incident";
    case "console":
      return entry.source === "chaos" ? "environment" : "console";
    default:
      return "order";
  }
}

type Props = {
  open: boolean;
  status: ConsoleStatus;
  offMessage: string | null;
  entries: TimelineEntry[];
  onToggle: () => void;
  onPick: (entry: TimelineEntry) => void;
};

/**
 * RF-39 para el público: cada paso con su hora y un título corto. Al tocar
 * uno se despliega en su lugar con la explicación ("Por qué este nodo",
 * "Por qué este dron") y el mapa vuela a donde pasó. Lo técnico de la
 * consola (reloj, actores, reinicio) no se cuenta.
 */
export function TimelinePanel({ open, status, offMessage, entries, onToggle, onPick }: Props) {
  const [filter, setFilter] = useState<Filter>("all");
  const [openId, setOpenId] = useState<string | null>(null);

  const visible = useMemo(
    () =>
      entries.filter((entry) => {
        const category = categoryOf(entry);
        if (category === "console") return false;
        return filter === "all" || category === filter;
      }),
    [entries, filter],
  );

  if (!open) {
    return (
      <>
        <div className="surface absolute left-5 top-[96px] z-20 hidden flex-col items-center gap-3 rounded-2xl p-2 md:flex">
          <IconButton label="Abrir la línea de tiempo" onClick={onToggle}>
            <ListIcon size={18} />
          </IconButton>
          {visible.length > 0 && <span className="figures text-[12px] text-muted">{visible.length}</span>}
        </div>
        <button
          type="button"
          onClick={onToggle}
          className="press surface absolute bottom-3 left-3 z-20 flex h-11 items-center gap-2 rounded-xl px-3 text-[14px] font-medium md:hidden"
        >
          <ListIcon size={16} className="text-muted" />
          Línea de tiempo
        </button>
      </>
    );
  }

  const toggleEntry = (entry: TimelineEntry) => {
    const opening = openId !== entry.id;
    setOpenId(opening ? entry.id : null);
    if (opening && (entry.orderId != null || entry.latitude != null || entry.hubId != null)) {
      onPick(entry);
    }
  };

  return (
    <aside
      aria-label="Línea de tiempo"
      className="surface enter-side absolute inset-x-3 bottom-3 top-[84px] z-30 flex flex-col overflow-hidden rounded-[20px] md:inset-x-auto md:bottom-5 md:left-5 md:top-[96px] md:z-20 md:w-[400px]"
    >
      <header className="flex items-center gap-2 px-5 pb-2 pt-4">
        <h2 className="flex-1 text-[17px] font-bold tracking-[-0.01em]">Línea de tiempo</h2>
        <IconButton label="Plegar la línea de tiempo" onClick={onToggle} className="!size-8">
          <ChevronIcon size={15} className="rotate-180" />
        </IconButton>
      </header>

      <div role="group" aria-label="Filtrar por tipo" className="flex flex-wrap gap-1.5 px-5 pb-3">
        {FILTERS.map((option) => {
          const active = filter === option.id;
          return (
            <button
              key={option.id}
              type="button"
              aria-pressed={active}
              onClick={() => setFilter(option.id)}
              className={`press h-8 rounded-full px-3 text-[12px] font-semibold ${
                active ? "bg-accent text-on-accent" : "border border-line text-text hover:bg-hover"
              }`}
            >
              {option.label}
            </button>
          );
        })}
      </div>
      <div className="h-px bg-line" />

      {status === "off" ? (
        <p className="px-5 py-8 text-[14px] leading-relaxed text-muted">
          {offMessage ?? "La consola de simulación está apagada."}
        </p>
      ) : status === "loading" ? (
        <ol aria-busy className="space-y-4 px-5 py-4">
          {[0, 1, 2].map((row) => (
            <li key={row} className="flex items-center gap-3">
              <span className="h-3 w-10 rounded bg-raised" />
              <span className="h-3 flex-1 rounded bg-raised" />
            </li>
          ))}
        </ol>
      ) : !visible.length ? (
        <div className="px-5 py-8 text-[14px] leading-relaxed text-muted">
          <p className="text-text">{entries.length ? "Nada de este tipo todavía." : "Todavía no pasa nada."}</p>
          <p className="mt-1">
            Cuando alguien pida, una central despache o lances un evento, cada paso queda aquí con su
            hora. Toca uno para ver por qué el sistema decidió así.
          </p>
        </div>
      ) : (
        <ol className="min-h-0 flex-1 space-y-0.5 overflow-y-auto overscroll-contain px-2.5 py-2">
          {visible.map((entry, index) => (
            <li key={entry.id} className={index === 0 ? "enter-up" : undefined}>
              <EntryRow entry={entry} open={openId === entry.id} onToggle={() => toggleEntry(entry)} />
            </li>
          ))}
        </ol>
      )}
    </aside>
  );
}

function EntryRow({
  entry,
  open,
  onToggle,
}: {
  entry: TimelineEntry;
  open: boolean;
  onToggle: () => void;
}) {
  const sections = entry.explanation?.length ? entry.explanation : null;
  const hasMore = sections != null || entry.detail != null;
  return (
    <div
      className={`rounded-[14px] border transition-colors duration-150 ${
        open ? "border-accent/45 bg-selected" : "border-transparent"
      }`}
    >
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={hasMore ? open : undefined}
        className="flex w-full items-center gap-3 rounded-[14px] px-2.5 py-2.5 text-left hover:bg-hover/60"
      >
        <span className="figures w-10 shrink-0 text-[12px] text-muted">{formatTime(entry.at)}</span>
        <span
          className={`size-2 shrink-0 rounded-full ${open && sections ? "bg-accent" : MARK[entry.severity]}`}
        />
        <span className={`min-w-0 flex-1 text-[14px] leading-snug ${open ? "font-bold" : "font-medium"}`}>
          {entry.title}
        </span>
        {entry.source === "chaos" && (
          <span className="shrink-0 text-[11px] font-semibold text-danger">Caos</span>
        )}
        {hasMore && (
          <ChevronIcon
            size={14}
            className={`shrink-0 text-muted transition-transform duration-200 ${open ? "-rotate-90" : "rotate-90"}`}
          />
        )}
      </button>

      {open && hasMore && (
        <div className="enter-up space-y-3 pb-3.5 pl-[66px] pr-4">
          {sections
            ? sections.map((section) => (
                <div key={section.title} className="space-y-1.5">
                  <p className="text-[11px] font-bold uppercase tracking-[0.06em] text-accent-strong">
                    {section.title}
                  </p>
                  {section.lines.map((line, index) => (
                    <p
                      key={line}
                      className={`text-[13px] leading-[1.45] ${index === 0 ? "text-text" : "text-muted"}`}
                    >
                      {line}
                    </p>
                  ))}
                </div>
              ))
            : entry.detail && <p className="text-[13px] leading-[1.45] text-muted">{entry.detail}</p>}
        </div>
      )}
    </div>
  );
}
