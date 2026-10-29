"use client";

import type { ReactNode } from "react";
import type { Connection } from "@/lib/source";
import type { HubSummary, RadarFlight } from "@/lib/types";
import { AlertIcon, CheckIcon, DroneIcon, HubIcon, LogoutIcon, ShieldIcon } from "./icons";
import { GlassButton, Pill, type Tone } from "./ui";

const CONNECTION: Record<Connection, { text: string; tone: Tone; pulse: boolean }> = {
  connecting: { text: "Conectando…", tone: "warn", pulse: false },
  live: { text: "En vivo", tone: "good", pulse: true },
  reconnecting: { text: "Reconectando…", tone: "warn", pulse: true },
  denied: { text: "Sin acceso", tone: "bad", pulse: false },
};

function Counter({ icon, value, label }: { icon: ReactNode; value: number; label: string }) {
  return (
    <div className="flex items-center gap-2" title={label}>
      <span className="grid size-8 place-items-center rounded-[10px] border border-glass-border bg-glass text-accent">
        {icon}
      </span>
      <div className="leading-none">
        <div className="text-lg font-semibold tabular-nums">{value}</div>
        <div className="mt-0.5 hidden text-[10px] font-semibold uppercase tracking-[0.12em] text-muted lg:block">
          {label}
        </div>
      </div>
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

/** La barra flotante de vidrio, como la de la app. */
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
    <header className="glass absolute inset-x-3 top-3 z-30 flex h-[68px] items-center gap-3 rounded-[22px] px-3 sm:inset-x-4 sm:top-4 sm:gap-5 sm:px-4">
      <div className="flex min-w-0 items-center gap-3">
        <span className="grid size-11 shrink-0 place-items-center rounded-[14px] bg-accent-gradient text-on-accent shadow-[0_8px_24px_-6px_var(--accent-glow)]">
          <DroneIcon size={24} strokeWidth={2} />
        </span>
        <div className="hidden min-w-0 leading-tight sm:block">
          <div className="text-base font-semibold tracking-tight">AirDrop Radar</div>
          <div className="text-xs text-muted">Valledupar · tiempo real</div>
        </div>
        {demo && (
          // En celular va debajo de la barra para no tapar los contadores.
          <span className="absolute left-3 top-full mt-2 sm:static sm:mt-0">
            <Pill tone="warn">Modo demostración</Pill>
          </span>
        )}
      </div>

      <div className="flex flex-1 items-center justify-center gap-4 sm:gap-6">
        <Counter icon={<HubIcon size={16} />} value={hubs.length} label="Centrales" />
        <Counter icon={<DroneIcon size={16} />} value={flights.length} label="En vuelo" />
        <Counter icon={<CheckIcon size={16} />} value={available} label="Drones libres" />
        {alerts > 0 && (
          <Pill tone="bad" icon={<AlertIcon size={13} />}>
            {alerts} {alerts === 1 ? "alerta" : "alertas"}
          </Pill>
        )}
      </div>

      <div className="flex items-center gap-2">
        <span role="status" title={status.text}>
          <Pill
            tone={status.tone}
            icon={
              <span className="relative flex size-2">
                {status.pulse && (
                  <span className="absolute inset-0 animate-ping rounded-full bg-current opacity-60 motion-reduce:animate-none" />
                )}
                <span className="relative size-2 rounded-full bg-current" />
              </span>
            }
          >
            <span className="sr-only sm:not-sr-only">{status.text}</span>
          </Pill>
        </span>
        <button
          type="button"
          onClick={onToggleGeofences}
          aria-pressed={showGeofences}
          title="Zonas restringidas"
          className={`hidden h-10 items-center gap-2 rounded-[13px] border px-3 text-xs font-semibold transition active:scale-95 focus-visible:outline-2 focus-visible:outline-accent md:flex ${
            showGeofences
              ? "border-danger/40 bg-danger/12 text-danger"
              : "border-glass-border bg-glass text-muted hover:text-text"
          }`}
        >
          <ShieldIcon size={16} />
          <span className="hidden xl:inline">Zonas restringidas</span>
        </button>
        {!demo && (
          <GlassButton label={userName ? `Salir (${userName})` : "Salir"} onClick={onLogout}>
            <LogoutIcon size={17} />
          </GlassButton>
        )}
      </div>
    </header>
  );
}
