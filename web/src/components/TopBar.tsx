"use client";

import type { Connection } from "@/lib/source";
import type { HubSummary, RadarFlight } from "@/lib/types";

const CONNECTION: Record<Connection, { text: string; dot: string }> = {
  connecting: { text: "Conectando…", dot: "bg-returning" },
  live: { text: "En vivo", dot: "bg-outbound animate-pulse" },
  reconnecting: { text: "Reconectando…", dot: "bg-returning animate-pulse" },
  denied: { text: "Sin acceso", dot: "bg-alert" },
};

function Counter({ value, label }: { value: number; label: string }) {
  return (
    <div className="flex items-baseline gap-1.5">
      <span className="font-mono text-lg font-semibold">{value}</span>
      <span className="hidden text-[11px] uppercase tracking-wider text-muted sm:inline">
        {label}
      </span>
    </div>
  );
}

type Props = {
  hubs: HubSummary[];
  flights: RadarFlight[];
  connection: Connection;
  demo: boolean;
  userName: string | null;
  showGeofences: boolean;
  onToggleGeofences: () => void;
  onLogout: () => void;
};

export function TopBar({
  hubs,
  flights,
  connection,
  demo,
  userName,
  showGeofences,
  onToggleGeofences,
  onLogout,
}: Props) {
  const status = CONNECTION[connection];
  const available = hubs.reduce((sum, hub) => sum + hub.fleet.available, 0);
  const alerts = flights.filter(
    (f) => f.alerts.battery || f.alerts.failure || f.alerts.coldChain,
  ).length;
  return (
    <header className="absolute inset-x-0 top-0 z-30 flex h-16 items-center gap-4 border-b border-line bg-ink/85 px-4 backdrop-blur-md">
      <div className="flex items-center gap-2.5">
        <span className="grid size-8 place-items-center rounded-lg bg-outbound text-ink" aria-hidden>
          <svg viewBox="0 0 24 24" className="size-5" fill="currentColor">
            <path d="M12 2l3 8 8 3-8 3-3 8-3-8-8-3 8-3z" />
          </svg>
        </span>
        <div className="leading-tight">
          <div className="text-sm font-semibold">AirDrop Radar</div>
          <div className="hidden text-[11px] text-muted sm:block">Valledupar · tiempo real</div>
        </div>
        {demo && (
          <span className="rounded-md bg-returning/15 px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider text-returning">
            Modo demostración
          </span>
        )}
      </div>

      <div className="ml-2 flex flex-1 items-center justify-center gap-5 sm:gap-8">
        <Counter value={hubs.length} label="Centrales" />
        <Counter value={flights.length} label="En vuelo" />
        <Counter value={available} label="Drones libres" />
        {alerts > 0 && (
          <span className="rounded-full bg-alert/15 px-2.5 py-0.5 text-xs font-semibold text-alert">
            ⚠ {alerts} {alerts === 1 ? "alerta" : "alertas"}
          </span>
        )}
      </div>

      <div className="flex items-center gap-3">
        <span className="flex items-center gap-2 text-xs text-muted" role="status">
          <span className={`size-2 rounded-full ${status.dot}`} />
          {status.text}
        </span>
        <button
          type="button"
          onClick={onToggleGeofences}
          aria-pressed={showGeofences}
          className={`hidden rounded-lg border px-2.5 py-1.5 text-xs font-medium transition focus-visible:outline-2 focus-visible:outline-hub md:block ${
            showGeofences ? "border-alert/50 text-alert" : "border-line text-muted"
          }`}
        >
          Zonas restringidas
        </button>
        {!demo && (
          <button
            type="button"
            onClick={onLogout}
            title={userName ?? undefined}
            className="rounded-lg border border-line px-2.5 py-1.5 text-xs font-medium text-muted transition hover:text-text focus-visible:outline-2 focus-visible:outline-hub"
          >
            Salir
          </button>
        )}
      </div>
    </header>
  );
}
