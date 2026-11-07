"use client";

import type { ReactNode } from "react";
import type { Connection } from "@/lib/source";
import type { HubSummary, RadarFlight } from "@/lib/types";
import { BrandLockup } from "./BrandMark";
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
      <span className="grid size-9 place-items-center rounded-[12px] border border-glass-border bg-glass text-accent">
        {icon}
      </span>
      <div className="leading-none">
        <div className="text-[22px] font-semibold tracking-[-0.03em] tabular-nums">{value}</div>
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
  /** El reloj simulado y sus controles (RF-31). */
  clock: ReactNode;
  /** Los actores simulados (RF-37), si la consola está encendida. */
  actors?: ReactNode;
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
  clock,
  actors,
}: Props) {
  const status = CONNECTION[connection];
  const available = hubs.reduce((sum, hub) => sum + hub.fleet.available, 0);
  const alerts = flights.filter(
    (f) => f.alerts.battery || f.alerts.failure || f.alerts.coldChain,
  ).length;
  return (
    <header className="glass absolute inset-x-3 top-3 z-30 flex h-[72px] items-center gap-3 rounded-[26px] px-3 sm:inset-x-4 sm:top-4 sm:gap-5 sm:px-4">
      <div className="flex min-w-0 items-center gap-3">
        <BrandLockup size={38} subtitle="Consola de simulación · Valledupar" />
        {demo && (
          // En celular va debajo de la barra para no tapar los contadores.
          <span className="absolute left-3 top-full mt-2 sm:static sm:mt-0">
            <Pill tone="warn">Modo demostración</Pill>
          </span>
        )}
      </div>

      <div className="hidden flex-1 items-center justify-center gap-4 sm:flex sm:gap-6">
        <Counter icon={<HubIcon size={16} />} value={hubs.length} label="Centrales" />
        <Counter icon={<DroneIcon size={16} />} value={flights.length} label="En vuelo" />
        <Counter icon={<CheckIcon size={16} />} value={available} label="Drones libres" />
        {alerts > 0 && (
          <Pill tone="bad" icon={<AlertIcon size={13} />}>
            {alerts} {alerts === 1 ? "alerta" : "alertas"}
          </Pill>
        )}
      </div>

      <div className="hidden h-10 w-px bg-glass-border md:block" />
      {clock}
      {actors}
      <div className="hidden h-10 w-px bg-glass-border md:block" />

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
          className={`hidden h-[46px] items-center gap-2 rounded-[15px] border px-3.5 text-xs font-semibold transition active:scale-95 focus-visible:outline-2 focus-visible:outline-accent md:flex ${
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
