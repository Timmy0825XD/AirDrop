"use client";

import type { ReactNode } from "react";
import type { Connection } from "@/lib/source";
import { Wordmark } from "./BrandMark";
import { LogoutIcon, ResetIcon, ShieldIcon } from "./icons";
import { IconButton, Pill, type Tone } from "./ui";

const CONNECTION: Record<Connection, { text: string; tone: Tone; live: boolean }> = {
  connecting: { text: "Conectando", tone: "warn", live: false },
  live: { text: "En vivo", tone: "good", live: true },
  reconnecting: { text: "Reconectando", tone: "warn", live: false },
  denied: { text: "Sin acceso", tone: "bad", live: false },
};

type Props = {
  connection: Connection;
  demo: boolean;
  userName: string | null;
  showGeofences: boolean;
  onToggleGeofences: () => void;
  onLogout: () => void;
  /** El reloj simulado y su velocidad (RF-31), al centro. */
  clock: ReactNode;
  /** Los actores simulados y el caos (RF-37, RF-38), si la consola está encendida. */
  actors?: ReactNode;
  /** Reiniciar el escenario (RF-40); `null` con la consola apagada. */
  onReset: (() => void) | null;
  busy: boolean;
};

/**
 * La barra de la consola: quién es (marca), qué hora es en la simulación y
 * los mandos que se usan poco. Fina y sólida; lo vivo está en el mapa.
 */
export function TopBar({
  connection,
  demo,
  userName,
  showGeofences,
  onToggleGeofences,
  onLogout,
  clock,
  actors,
  onReset,
  busy,
}: Props) {
  const status = CONNECTION[connection];
  return (
    <header className="relative z-30 flex h-16 shrink-0 items-center gap-3 border-b border-line bg-panel px-3 sm:gap-4 sm:px-5">
      {/* En celular cada lado ocupa lo suyo; desde sm, la hora queda al centro. */}
      <div className="flex min-w-0 items-center gap-3 sm:flex-1">
        <span className="shrink-0">
          <Wordmark caption="Consola de simulación" />
        </span>
        {demo && (
          <>
            <span className="hidden sm:inline-flex">
              <Pill tone="warn">Demostración</Pill>
            </span>
            <span className="text-[12px] font-medium text-warning sm:hidden">Demo</span>
          </>
        )}
      </div>

      {clock}

      <div className="ml-auto flex items-center justify-end gap-2 sm:ml-0 sm:flex-1">
        <span role="status" className="mr-1 flex items-center gap-2 text-[13px] text-muted" title={status.text}>
          <span className={`relative flex size-2 ${status.tone === "good" ? "text-success" : status.tone === "bad" ? "text-danger" : "text-warning"}`}>
            {status.live && (
              <span className="absolute inset-0 animate-ping rounded-full bg-current opacity-50 motion-reduce:hidden" />
            )}
            <span className="relative size-2 rounded-full bg-current" />
          </span>
          <span className="hidden lg:inline">{status.text}</span>
        </span>
        {actors}
        <span className="hidden md:block">
          <IconButton
            label={showGeofences ? "Ocultar las zonas restringidas" : "Mostrar las zonas restringidas"}
            onClick={onToggleGeofences}
            pressed={showGeofences}
            active={showGeofences}
          >
            <ShieldIcon size={18} />
          </IconButton>
        </span>
        {onReset && (
          <span className="hidden md:block">
            <IconButton label="Reiniciar el escenario" onClick={onReset} disabled={busy}>
              <ResetIcon size={18} />
            </IconButton>
          </span>
        )}
        {!demo && (
          <IconButton label={userName ? `Salir (${userName})` : "Salir"} onClick={onLogout}>
            <LogoutIcon size={18} />
          </IconButton>
        )}
      </div>
    </header>
  );
}
