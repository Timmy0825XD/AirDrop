"use client";

import { useEffect, useState, type ReactNode } from "react";
import type { ConsoleIncidentKind } from "@/lib/types";
import {
  BatteryLowIcon,
  CollisionIcon,
  GpsIcon,
  LinkOffIcon,
  LostIcon,
  MotorIcon,
  SnowflakeIcon,
} from "./icons";
import { Section } from "./ui";

type Item = {
  kind: ConsoleIncidentKind;
  label: string;
  effect: string;
  icon: (size: number) => ReactNode;
  /** Grave: pide confirmar con un segundo toque. */
  severe?: boolean;
};

/** RF-34: el catálogo, con lo que le hace al resto del vuelo. */
const CATALOG: Item[] = [
  { kind: "battery_degraded", label: "Batería degradada", effect: "+25 % de consumo", icon: (s) => <BatteryLowIcon size={s} /> },
  { kind: "motor_failure", label: "Falla de 1 motor", effect: "+15 % de consumo, -10 % de velocidad", icon: (s) => <MotorIcon size={s} /> },
  { kind: "collision_minor", label: "Choque leve", effect: "+10 % de consumo", icon: (s) => <CollisionIcon size={s} /> },
  { kind: "gps_loss_minor", label: "GPS con falla", effect: "Sigue con el respaldo", icon: (s) => <GpsIcon size={s} /> },
  { kind: "link_loss", label: "Pérdida de enlace", effect: "Vuelve solo a la central", icon: (s) => <LinkOffIcon size={s} /> },
  { kind: "cooling_failure", label: "Falla del frío", effect: "La carga se calienta", icon: (s) => <SnowflakeIcon size={s} /> },
  { kind: "dual_motor_failure", label: "Falla de 2 motores", effect: "Aterrizaje de emergencia", icon: (s) => <MotorIcon size={s} />, severe: true },
  { kind: "gps_loss_major", label: "Sin GPS", effect: "Aterrizaje de emergencia", icon: (s) => <GpsIcon size={s} />, severe: true },
  { kind: "collision_major", label: "Choque grave", effect: "Cae; fuera de servicio", icon: (s) => <CollisionIcon size={s} />, severe: true },
  { kind: "drone_lost", label: "Dron perdido", effect: "Sin rastro; fuera de servicio", icon: (s) => <LostIcon size={s} />, severe: true },
];

/**
 * CU-38: lanzar un incidente sobre el dron elegido. La respuesta (seguir,
 * volver o aterrizar) la decide el sistema con las reglas de RF-34.
 */
export function IncidentActions({
  cold,
  busy,
  disabledReason,
  onLaunch,
}: {
  /** Lleva carga con frío: solo entonces aplica la falla de la refrigeración. */
  cold: boolean;
  busy: boolean;
  /** Por qué no se puede (consola apagada, demostración); `null` si se puede. */
  disabledReason: string | null;
  onLaunch: (kind: ConsoleIncidentKind) => void;
}) {
  const [armed, setArmed] = useState<ConsoleIncidentKind | null>(null);

  // El segundo toque vale 4 s; después hay que volver a empezar.
  useEffect(() => {
    if (!armed) return;
    const timer = setTimeout(() => setArmed(null), 4_000);
    return () => clearTimeout(timer);
  }, [armed]);

  return (
    <Section title="Lanzar un incidente">
      {disabledReason && <p className="mb-3 text-[13px] text-muted">{disabledReason}</p>}
      <div className="grid grid-cols-2 gap-1.5">
        {CATALOG.filter((item) => item.kind !== "cooling_failure" || cold).map((item) => {
          const confirming = armed === item.kind;
          return (
            <button
              key={item.kind}
              type="button"
              disabled={busy || disabledReason != null}
              onClick={() => {
                if (item.severe && !confirming) {
                  setArmed(item.kind);
                  return;
                }
                setArmed(null);
                onLaunch(item.kind);
              }}
              className={`press flex min-h-[60px] items-start gap-2.5 rounded-lg border px-3 py-2.5 text-left disabled:opacity-40 ${
                confirming
                  ? "border-danger bg-danger/16"
                  : item.severe
                    ? "border-danger/30 hover:border-danger/55 hover:bg-danger/8"
                    : "border-line hover:border-line-strong hover:bg-hover"
              }`}
            >
              <span className={`mt-px shrink-0 ${item.severe ? "text-danger" : "text-muted"}`}>
                {item.icon(17)}
              </span>
              <span className="min-w-0">
                <span
                  className={`block text-[13px] font-medium leading-tight ${confirming ? "text-danger" : "text-text"}`}
                >
                  {confirming ? "Toca otra vez para lanzar" : item.label}
                </span>
                <span className="mt-1 block text-[11.5px] leading-tight text-muted">{item.effect}</span>
              </span>
            </button>
          );
        })}
      </div>
    </Section>
  );
}
