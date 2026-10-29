"use client";

import { useCallback } from "react";
import { daysUntil, label, DRONE_STATUS, HUB_TYPE, PHASE, QUEUE_STATUS, SALE_TYPE } from "@/lib/labels";
import type { RadarSource } from "@/lib/source";
import type { HubDetail, HubDrone, InventoryRow, Selection } from "@/lib/types";
import { usePolled } from "@/lib/use-polled";
import { PanelMessage, PanelShell, Pill, Section, Stat } from "./ui";

const REFRESH_MS = 5_000;

const droneTone = {
  available: "good",
  in_mission: "info",
  maintenance: "warn",
  out_of_service: "bad",
} as const;

function DroneRow({ drone, onSelect }: { drone: HubDrone; onSelect: (s: Selection) => void }) {
  const flight = drone.flight;
  return (
    <li className="flex items-center gap-3 rounded-xl border border-line bg-panel-2/40 px-3 py-2">
      <div className="min-w-0 flex-1">
        <div className="truncate font-mono text-sm font-medium">{drone.identifier}</div>
        <div className="truncate text-xs text-muted">
          {drone.status === "maintenance" && drone.maintenanceReason
            ? drone.maintenanceReason
            : flight
              ? `${label(PHASE, flight.phase)} · ${flight.batteryPercent ?? "—"} %`
              : (drone.modelName ?? "—")}
        </div>
      </div>
      <Pill tone={droneTone[drone.status]}>{label(DRONE_STATUS, drone.status)}</Pill>
      {flight && (
        <button
          type="button"
          onClick={() => onSelect({ kind: "flight", id: flight.orderId })}
          className="rounded-lg bg-outbound px-2.5 py-1 text-xs font-semibold text-ink transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-white"
        >
          Ver vuelo
        </button>
      )}
    </li>
  );
}

function ExpiryPill({ date }: { date: string }) {
  const days = daysUntil(date);
  if (days < 0) return <Pill tone="bad">Vencido</Pill>;
  if (days <= 30) return <Pill tone="warn">Vence en {days} d</Pill>;
  return <span className="font-mono text-xs text-muted">{date}</span>;
}

function InventoryTable({ items }: { items: InventoryRow[] }) {
  if (!items.length) return <p className="text-sm text-muted">Sin existencias registradas.</p>;
  return (
    <ul className="divide-y divide-line rounded-xl border border-line">
      {items.map((item) => (
        <li key={item.id} className="flex items-center gap-3 px-3 py-2.5">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5 truncate text-sm font-medium">
              {item.requiresColdChain && (
                <span title="Cadena de frío" className="text-hub">
                  ❄
                </span>
              )}
              <span className="truncate">{item.name}</span>
            </div>
            <div className="truncate text-xs text-muted">
              Lote {item.lot} · {label(SALE_TYPE, item.saleType)}
            </div>
          </div>
          <div className="text-right">
            <div className="font-mono text-sm font-semibold">{item.quantity}</div>
            <ExpiryPill date={item.expirationDate} />
          </div>
        </li>
      ))}
    </ul>
  );
}

function HubBody({ hub, onSelect }: { hub: HubDetail; onSelect: (s: Selection) => void }) {
  const queue = Object.entries(hub.queue);
  return (
    <>
      <Section title="Flota">
        <div className="grid grid-cols-4 gap-2">
          <Stat label="Libres" value={hub.fleet.available} tone="good" />
          <Stat label="Vuelo" value={hub.fleet.inMission} />
          <Stat label="Taller" value={hub.fleet.maintenance} />
          <Stat label="Total" value={hub.fleet.total} />
        </div>
        {hub.drones.length > 0 && (
          <ul className="mt-3 space-y-2">
            {hub.drones.map((drone) => (
              <DroneRow key={drone.id} drone={drone} onSelect={onSelect} />
            ))}
          </ul>
        )}
      </Section>

      <Section title="Pedidos en marcha">
        {queue.length ? (
          <div className="flex flex-wrap gap-2">
            {queue.map(([status, count]) => (
              <span key={status} className="rounded-lg border border-line bg-panel-2/60 px-2.5 py-1.5 text-xs">
                <span className="font-mono font-semibold">{count}</span>{" "}
                <span className="text-muted">{label(QUEUE_STATUS, status)}</span>
              </span>
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted">No hay pedidos en marcha.</p>
        )}
      </Section>

      <Section
        title="Inventario"
        aside={
          <span className="text-xs text-muted">
            <span className="font-mono text-text">{hub.inventory.totalUnits}</span> unidades
          </span>
        }
      >
        {hub.inventory.quarantinedUnits > 0 && (
          <p className="mb-3 rounded-lg bg-returning/10 px-3 py-2 text-xs text-returning">
            {hub.inventory.quarantinedUnits} unidades en cuarentena (no están a la venta).
          </p>
        )}
        <InventoryTable items={hub.inventory.items} />
      </Section>
    </>
  );
}

type Props = {
  source: RadarSource;
  hubId: string;
  onSelect: (selection: Selection) => void;
};

export function HubPanel({ source, hubId, onSelect }: Props) {
  const load = useCallback(() => source.hub(hubId), [source, hubId]);
  const { data, error } = usePolled(load, hubId, REFRESH_MS);
  const close = () => onSelect(null);

  if (!data) {
    return (
      <PanelShell title="Central" onClose={close}>
        <PanelMessage>{error ?? "Cargando la central…"}</PanelMessage>
      </PanelShell>
    );
  }
  return (
    <PanelShell
      title={data.name}
      subtitle={data.address}
      onClose={close}
      badge={
        <>
          <Pill tone="info">{label(HUB_TYPE, data.type)}</Pill>
          <Pill tone={data.status === "active" ? "good" : "bad"}>
            {data.status === "active" ? "Activa" : "Suspendida"}
          </Pill>
        </>
      }
    >
      <div className="px-5 pb-4 text-sm text-muted">
        <a href={`tel:${data.contactPhone}`} className="hover:text-text">
          {data.contactPhone}
        </a>
        {data.contactEmail && (
          <>
            {" · "}
            <a href={`mailto:${data.contactEmail}`} className="hover:text-text">
              {data.contactEmail}
            </a>
          </>
        )}
        {error && <p className="mt-2 text-alert">Sin conexión: {error}</p>}
      </div>
      <HubBody hub={data} onSelect={onSelect} />
    </PanelShell>
  );
}
