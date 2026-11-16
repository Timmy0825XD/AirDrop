"use client";

import type { ReactNode } from "react";
import type { Connection } from "@/lib/source";
import type { Theme } from "@/lib/theme";
import { Wordmark } from "./BrandMark";
import { LogoutIcon, MoonIcon, ResetIcon, ShieldIcon, SunIcon } from "./icons";
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
  /** RF-44: de qué hora a qué hora se vuela hoy. */
  daylight?: ReactNode;
  /** Reiniciar el escenario (RF-40); `null` con la consola apagada. */
  onReset: (() => void) | null;
  busy: boolean;
  theme: Theme;
  onToggleTheme: () => void;
};

/**
 * La barra de la consola: tarjetas que flotan sobre el mapa, como en la app.
 * A la izquierda quién es (marca), al centro la hora simulada y a la derecha
 * los mandos. Entre tarjetas el mapa sigue visible.
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
  daylight,
  onReset,
  busy,
  theme,
  onToggleTheme,
}: Props) {
  const status = CONNECTION[connection];
  return (
    <header className="pointer-events-none absolute inset-x-3 top-3 z-30 flex items-center gap-2 sm:inset-x-5 sm:top-5 sm:gap-3">
      <div className="surface pointer-events-auto flex h-14 min-w-0 shrink-0 items-center gap-3 rounded-2xl px-3">
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

      <div className="surface pointer-events-auto flex h-14 shrink-0 items-center gap-2 rounded-2xl px-2">
        {clock}
        {daylight}
      </div>

      <div className="flex-1" />

      <div className="surface pointer-events-auto flex h-14 shrink-0 items-center justify-end gap-1.5 rounded-2xl px-2">
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
        <IconButton
          label={theme === "dark" ? "Cambiar a tema claro" : "Cambiar a tema oscuro"}
          onClick={onToggleTheme}
        >
          {theme === "dark" ? <SunIcon size={18} /> : <MoonIcon size={18} />}
        </IconButton>
        {!demo && (
          <IconButton label={userName ? `Salir (${userName})` : "Salir"} onClick={onLogout}>
            <LogoutIcon size={18} />
          </IconButton>
        )}
      </div>
    </header>
  );
}
