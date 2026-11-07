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
 * RF-39: las alertas de vuelo que siguen abiertas, arriba del mapa y siempre
 * a la vista. Tocar una lleva el mapa al dron y abre su vuelo.
 */
export function AlertsTray({ alerts, className, onPick }: Props) {
  if (!alerts.length) return null;
  return (
    <div
      role="region"
      aria-label="Alertas pendientes"
      className={`pointer-events-none absolute top-3 z-20 flex justify-center ${className}`}
    >
      <div className="enter-up pointer-events-auto flex max-w-full items-center gap-1 overflow-x-auto rounded-xl border border-danger/45 bg-panel p-1 shadow-[0_10px_30px_-14px_var(--shadow)]">
        <span className="flex shrink-0 items-center gap-2 px-2.5 text-[13px] font-medium text-danger">
          <AlertIcon size={16} />
          <span className="figures">{alerts.length}</span>
          {alerts.length === 1 ? "alerta" : "alertas"}
        </span>
        {alerts.map((alert) => (
          <button
            key={alert.orderId}
            type="button"
            onClick={() => onPick(alert)}
            className="press flex h-9 shrink-0 items-center gap-2 rounded-lg bg-danger/10 px-3 text-[13px] hover:bg-danger/18"
          >
            <span className="figures font-medium text-text">{alert.identifier}</span>
            <span className="text-danger">
              {alert.kinds.map((kind) => label(ALERT_KIND, kind)).join(" · ")}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
