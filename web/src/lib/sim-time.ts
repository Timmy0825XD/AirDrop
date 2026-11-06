"use client";

import { useEffect, useState } from "react";
import type { ClockView } from "./types";

/**
 * RF-31: la hora la manda el backend (`clock`). Entre un aviso y otro se
 * avanza aquí con la velocidad que trae, para que el reloj de la TV corra
 * suave; en pausa se queda quieta.
 */
export type ReceivedClock = ClockView & { receivedAt: number };

export function simNowMs(clock: ReceivedClock, realNow = Date.now()): number {
  const base = Date.parse(clock.now);
  return clock.paused ? base : base + (realNow - clock.receivedAt) * clock.speed;
}

/** La hora simulada, repintada dos veces por segundo. */
export function useSimNow(clock: ReceivedClock | null): number | null {
  const [now, setNow] = useState<number | null>(null);
  useEffect(() => {
    if (!clock) return;
    const tick = () => setNow(simNowMs(clock));
    tick();
    const timer = setInterval(tick, 500);
    return () => clearInterval(timer);
  }, [clock]);
  return clock ? now : null;
}

const TIME = new Intl.DateTimeFormat("es-CO", {
  timeZone: "America/Bogota",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false,
});

const DAY = new Intl.DateTimeFormat("es-CO", {
  timeZone: "America/Bogota",
  weekday: "short",
  day: "numeric",
  month: "short",
});

/** "15:04:32", en hora de Colombia. */
export const formatTime = (ms: number | string) =>
  TIME.format(typeof ms === "string" ? Date.parse(ms) : ms);

/** "mié, 5 nov". */
export const formatDay = (ms: number) => DAY.format(ms);
