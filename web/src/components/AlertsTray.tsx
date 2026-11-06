"use client";

import { ALERT_KIND, label } from "@/lib/labels";
import type { PendingAlert } from "@/lib/types";
import { AlertIcon } from "./icons";

type Props = {
  alerts: PendingAlert[];
  className: string;
  onPick: (alert: PendingAlert) => void;
};

/**
 * RF-39: las alertas de vuelo que siguen abiertas, siempre a la vista.
 * Tocar una lleva el mapa al dron y abre su vuelo.
 */
export function AlertsTray({ alerts, className, onPick }: Props) {
  if (!alerts.length) return null;
  return (
    <div
      role="region"
      aria-label="Alertas pendientes"
      className={`pointer-events-none absolute top-[96px] z-20 flex justify-center ${className}`}
    >
      <div className="glass rise-in pointer-events-auto flex max-w-full items-center gap-2 overflow-x-auto rounded-2xl !border-danger/40 p-2">
        <span className="flex shrink-0 items-center gap-2 px-2 text-sm font-semibold text-danger">
          <AlertIcon size={18} />
          {alerts.length === 1 ? "1 alerta" : `${alerts.length} alertas`}
        </span>
        {alerts.map((alert) => (
          <button
            key={alert.orderId}
            type="button"
            onClick={() => onPick(alert)}
            className="flex h-10 shrink-0 items-center gap-2 rounded-xl border border-danger/35 bg-danger/12 px-3 text-sm font-semibold text-text transition hover:bg-danger/20 active:scale-95 focus-visible:outline-2 focus-visible:outline-danger"
          >
            <span className="tabular-nums">{alert.identifier}</span>
            <span className="font-medium text-danger">
              {alert.kinds.map((kind) => label(ALERT_KIND, kind)).join(" · ")}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
