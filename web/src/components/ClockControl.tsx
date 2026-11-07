"use client";

import type { ReactNode } from "react";
import type { ClockChange } from "@/lib/source";
import { formatDay, formatTime, type ReceivedClock, useSimNow } from "@/lib/sim-time";
import type { ClockSpeed } from "@/lib/types";
import type { ConsoleStatus } from "@/lib/use-console";
import { PauseIcon, PlayIcon } from "./icons";
import { Pill } from "./ui";

const SPEEDS: ClockSpeed[] = [1, 2, 4, 8];

type Props = {
  clock: ReceivedClock | null;
  status: ConsoleStatus;
  offMessage: string | null;
  busy: boolean;
  onChange: (change: ClockChange) => void;
};

/**
 * RF-31: la hora simulada, grande y en mono para leerla desde lejos, y su
 * velocidad. Pausa, x1, x2, x4 y x8 cambian el reloj de todo el sistema
 * (también el de la app en los celulares).
 */
export function ClockControl({ clock, status, offMessage, busy, onChange }: Props) {
  const now = useSimNow(clock);
  const on = status === "on";
  const paused = clock?.paused ?? false;

  return (
    <div className="flex items-center gap-4">
      <div className="flex items-baseline gap-2.5" aria-live="off">
        <span className="figures text-[20px] font-medium leading-none text-text sm:text-[24px]">
          {now == null ? "--:--:--" : formatTime(now)}
        </span>
        <span className="hidden text-[13px] text-muted xl:inline">
          {now == null ? "Hora simulada" : formatDay(now)}
        </span>
        {clock && (paused || clock.speed > 1) && (
          <span className={`figures text-[13px] font-medium ${paused ? "text-warning" : "text-accent"}`}>
            {paused ? "En pausa" : `x${clock.speed}`}
          </span>
        )}
      </div>

      {status === "off" && (
        <span title={offMessage ?? undefined}>
          <Pill tone="neutral">Consola apagada</Pill>
        </span>
      )}

      {on && clock && (
        <div
          role="group"
          aria-label="Velocidad del reloj"
          className="hidden items-center rounded-lg border border-line bg-ground p-0.5 md:flex"
        >
          <SpeedButton
            label={paused ? "Reanudar el reloj" : "Pausar el reloj"}
            active={paused}
            disabled={busy}
            onClick={() => onChange({ paused: !paused })}
          >
            {paused ? <PlayIcon size={14} /> : <PauseIcon size={14} />}
          </SpeedButton>
          <span className="mx-0.5 h-4 w-px bg-line" />
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
      className={`press figures grid h-8 min-w-10 place-items-center rounded-md px-2 text-[13px] font-medium disabled:opacity-50 ${
        active ? "bg-raised text-text shadow-[inset_0_0_0_1px_var(--line-strong)]" : "text-muted hover:text-text"
      }`}
    >
      {children}
    </button>
  );
}
