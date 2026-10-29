"use client";

import { useCallback } from "react";
import { daysUntil, label, DRONE_STATUS, HUB_TYPE, PHASE, QUEUE_STATUS, SALE_TYPE } from "@/lib/labels";
import type { RadarSource } from "@/lib/source";
import type { HubDetail, HubDrone, InventoryRow, Selection } from "@/lib/types";
import { usePolled } from "@/lib/use-polled";
import {
  ChevronIcon,
  DroneIcon,
  HubTypeIcon,
  ListIcon,
  MailIcon,
  PackageIcon,
  PhoneIcon,
  SnowflakeIcon,
} from "./icons";
import { IconTile, PanelMessage, PanelShell, Pill, Section, Stat, TONE_TEXT } from "./ui";

const REFRESH_MS = 5_000;

const droneTone = {
  available: "good",
  in_mission: "info",
  maintenance: "warn",
  out_of_service: "bad",
} as const;

function DroneRow({ drone, onSelect }: { drone: HubDrone; onSelect: (s: Selection) => void }) {
  const flight = drone.flight;
  const tone = droneTone[drone.status];
  return (
    <li className="flex items-center gap-3 rounded-2xl border border-glass-border bg-glass px-3 py-2.5">
      <span
        className={`grid size-9 shrink-0 place-items-center rounded-xl bg-sunk ${TONE_TEXT[tone]}`}
      >
        <DroneIcon size={20} />
      </span>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold">{drone.identifier}</div>
        <div className="truncate text-xs text-muted">
          {drone.status === "maintenance" && drone.maintenanceReason
            ? drone.maintenanceReason
            : flight
              ? `${label(PHASE, flight.phase)} · ${flight.batteryPercent ?? "—"} %`
              : (drone.modelName ?? "—")}
        </div>
      </div>
      {/* En celular, con vuelo, el botón ya dice que está en misión. */}
      <span className={flight ? "hidden sm:block" : undefined}>
        <Pill tone={tone}>{label(DRONE_STATUS, drone.status)}</Pill>
      </span>
      {flight && (
        <button
          type="button"
          onClick={() => onSelect({ kind: "flight", id: flight.orderId })}
          className="flex shrink-0 items-center gap-0.5 rounded-xl bg-accent-gradient py-1.5 pl-2.5 pr-1.5 text-xs font-bold text-on-accent transition hover:brightness-110 active:scale-95 focus-visible:outline-2 focus-visible:outline-text"
        >
          Ver vuelo
          <ChevronIcon size={14} strokeWidth={2.4} />
        </button>
      )}
    </li>
  );
}

function ExpiryPill({ date }: { date: string }) {
  const days = daysUntil(date);
  if (days < 0) return <Pill tone="bad">Vencido</Pill>;
  if (days <= 30) return <Pill tone="warn">Vence en {days} d</Pill>;
  return <span className="text-xs tabular-nums text-muted">{date}</span>;
}

function InventoryTable({ items }: { items: InventoryRow[] }) {
  if (!items.length) return <p className="text-sm text-muted">Sin existencias registradas.</p>;
  return (
    <ul className="divide-y divide-glass-border overflow-hidden rounded-2xl border border-glass-border bg-glass">
      {items.map((item) => (
        <li key={item.id} className="flex items-center gap-3 px-3.5 py-3">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5 text-sm font-medium">
              {item.requiresColdChain && (
                <span title="Cadena de frío" className="shrink-0 text-info">
                  <SnowflakeIcon size={14} />
                </span>
              )}
              <span className="truncate">{item.name}</span>
            </div>
            <div className="truncate text-xs text-muted">
              Lote {item.lot} · {label(SALE_TYPE, item.saleType)}
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <div className="text-sm font-semibold tabular-nums">{item.quantity}</div>
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
      <Section title="Flota" icon={<DroneIcon size={14} />}>
        <div className="grid grid-cols-4 gap-2">
          <Stat label="Libres" value={hub.fleet.available} tone="good" />
          <Stat label="Vuelo" value={hub.fleet.inMission} tone="info" />
          <Stat label="Taller" value={hub.fleet.maintenance} tone={hub.fleet.maintenance ? "warn" : undefined} />
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

      <Section title="Pedidos en marcha" icon={<ListIcon size={14} />}>
        {queue.length ? (
          <div className="flex flex-wrap gap-2">
            {queue.map(([status, count]) => (
              <span
                key={status}
                className="flex items-baseline gap-1.5 rounded-xl border border-glass-border bg-glass px-3 py-2 text-xs"
              >
                <span className="text-base font-semibold tabular-nums">{count}</span>
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
        icon={<PackageIcon size={14} />}
        aside={
          <span className="text-xs text-muted">
            <span className="font-semibold tabular-nums text-text">{hub.inventory.totalUnits}</span> unidades
          </span>
        }
      >
        {hub.inventory.quarantinedUnits > 0 && (
          <p className="mb-3 rounded-xl border border-warning/30 bg-warning/10 px-3 py-2.5 text-xs font-medium text-warning">
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
      <PanelShell
        title="Central"
        icon={<IconTile><HubTypeIcon type="" size={24} /></IconTile>}
        onClose={close}
      >
        <PanelMessage failed={Boolean(error)}>{error ?? "Cargando la central…"}</PanelMessage>
      </PanelShell>
    );
  }
  const active = data.status === "active";
  return (
    <PanelShell
      title={data.name}
      subtitle={data.address}
      icon={
        <IconTile tone={active ? "info" : "neutral"}>
          <HubTypeIcon type={data.type} size={24} />
        </IconTile>
      }
      onClose={close}
      badge={
        <>
          <Pill tone="info" icon={<HubTypeIcon type={data.type} size={12} strokeWidth={2.2} />}>
            {label(HUB_TYPE, data.type)}
          </Pill>
          <Pill tone={active ? "good" : "bad"}>{active ? "Activa" : "Suspendida"}</Pill>
        </>
      }
    >
      <div className="flex flex-wrap gap-2 px-5 py-4 text-sm">
        <a
          href={`tel:${data.contactPhone}`}
          className="flex items-center gap-2 rounded-xl border border-glass-border bg-glass px-3 py-2 text-muted transition hover:text-text"
        >
          <PhoneIcon size={14} className="text-accent" />
          {data.contactPhone}
        </a>
        {data.contactEmail && (
          <a
            href={`mailto:${data.contactEmail}`}
            className="flex min-w-0 items-center gap-2 rounded-xl border border-glass-border bg-glass px-3 py-2 text-muted transition hover:text-text"
          >
            <MailIcon size={14} className="shrink-0 text-accent" />
            <span className="truncate">{data.contactEmail}</span>
          </a>
        )}
        {error && (
          <p role="alert" className="w-full text-xs text-danger">
            Sin conexión: {error}
          </p>
        )}
      </div>
      <HubBody hub={data} onSelect={onSelect} />
    </PanelShell>
  );
}
