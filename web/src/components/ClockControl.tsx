"use client";

import type { ReactNode } from "react";
import type { ClockChange } from "@/lib/source";
import { formatDay, formatTime, type ReceivedClock, useSimNow } from "@/lib/sim-time";
import type { ClockSpeed } from "@/lib/types";
import type { ConsoleStatus } from "@/lib/use-console";
import { ClockIcon, PauseIcon, PlayIcon, ResetIcon } from "./icons";
import { Pill } from "./ui";

const SPEEDS: ClockSpeed[] = [1, 2, 4, 8];

type Props = {
  clock: ReceivedClock | null;
  status: ConsoleStatus;
  offMessage: string | null;
  busy: boolean;
  onChange: (change: ClockChange) => void;
  onReset: () => void;
};

/**
 * RF-31: la hora simulada y su velocidad. Pausa, x1, x2, x4 y x8 cambian el
 * reloj de todo el sistema (también el de la app en los celulares).
 */
export function ClockControl({ clock, status, offMessage, busy, onChange, onReset }: Props) {
  const now = useSimNow(clock);
  const on = status === "on";
  const paused = clock?.paused ?? false;

  return (
    <div className="flex items-center gap-3">
      <div className="flex items-center gap-2.5" aria-live="off">
        <span className="hidden size-10 place-items-center rounded-[13px] border border-glass-border bg-glass text-accent lg:grid">
          <ClockIcon size={18} />
        </span>
        <div className="leading-none">
          <div className="text-[22px] font-semibold tabular-nums tracking-tight">
            {now == null ? "--:--:--" : formatTime(now)}
          </div>
          <div className="mt-1 hidden text-[11px] font-semibold uppercase tracking-[0.12em] text-muted sm:block">
            {now == null ? "Hora simulada" : formatDay(now)}
            {clock && (
              <span className={paused ? "text-warning" : clock.speed > 1 ? "text-accent" : ""}>
                {" · "}
                {paused ? "En pausa" : `x${clock.speed}`}
              </span>
            )}
          </div>
        </div>
      </div>

      {status === "off" && (
        <span title={offMessage ?? undefined}>
          <Pill tone="neutral">Consola apagada</Pill>
        </span>
      )}

      {on && clock && (
        <>
          <div
            role="group"
            aria-label="Velocidad del reloj"
            className="hidden items-center gap-1 rounded-[15px] border border-glass-border bg-glass p-1 md:flex"
          >
            <SpeedButton
              label={paused ? "Reanudar" : "Pausa"}
              active={paused}
              disabled={busy}
              onClick={() => onChange({ paused: !paused })}
            >
              {paused ? <PlayIcon size={15} /> : <PauseIcon size={15} />}
              <span className="hidden xl:inline">{paused ? "Reanudar" : "Pausa"}</span>
            </SpeedButton>
            {SPEEDS.map((speed) => (
              <SpeedButton
                key={speed}
                label={`Velocidad x${speed}`}
                active={!paused && clock.speed === speed}
                disabled={busy}
                onClick={() => onChange({ speed, paused: false })}
              >
                x{speed}
              </SpeedButton>
            ))}
          </div>
          <button
            type="button"
            onClick={onReset}
            disabled={busy}
            title="Reiniciar el escenario"
            className="hidden h-10 items-center gap-2 rounded-[13px] border border-glass-border bg-glass px-3 text-sm font-semibold text-text transition hover:border-danger/40 hover:text-danger active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent md:flex"
          >
            <ResetIcon size={16} />
            <span className="hidden 2xl:inline">Reiniciar</span>
          </button>
        </>
      )}
    </div>
  );
}

function SpeedButton({
  label,
  active,
  disabled,
  onClick,
  children,
}: {
  label: string;
  active: boolean;
  disabled: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      aria-pressed={active}
      title={label}
      className={`flex h-9 min-w-11 items-center justify-center gap-1.5 rounded-[11px] px-2.5 text-sm font-semibold tabular-nums transition active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent ${
        active
          ? "bg-accent-gradient text-on-accent shadow-[0_6px_18px_-6px_var(--accent-glow)]"
          : "text-muted hover:bg-white/10 hover:text-text"
      }`}
    >
      {children}
    </button>
  );
}
