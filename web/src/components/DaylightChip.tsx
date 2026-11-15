"use client";

import type { Daylight } from "@/lib/types";

const HOUR = new Intl.DateTimeFormat("es-CO", {
  timeZone: "America/Bogota",
  hour: "2-digit",
  minute: "2-digit",
  hour12: false,
});

/**
 * RF-44: de qué hora a qué hora se vuela en el día simulado. De noche lo
 * dice en ámbar: las urgencias van por la alternativa terrestre. El texto
 * acompaña siempre al color.
 */
export function DaylightChip({ day }: { day: Daylight | null }) {
  if (!day) return null;
  const hours = `${HOUR.format(Date.parse(day.sunrise))} – ${HOUR.format(Date.parse(day.sunset))}`;
  return (
    <span
      role="status"
      title={
        day.daylight
          ? `Se vuela de ${hours}`
          : `De noche no se vuela: las urgencias van por tierra. Se vuela de ${hours}`
      }
      className={`hidden items-center gap-2 rounded-lg border px-3 py-1.5 text-[13px] xl:flex ${
        day.daylight ? "border-line text-muted" : "border-warning/45 text-warning"
      }`}
    >
      <span className="font-medium">{day.daylight ? "De día" : "De noche: urgencias por tierra"}</span>
      <span className="figures">{hours}</span>
    </span>
  );
}
