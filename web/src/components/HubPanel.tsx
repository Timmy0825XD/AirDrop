"use client";

import { useCallback, useState } from "react";
import { formatTime } from "@/lib/sim-time";
import { daysUntil, label, DRONE_STATUS, HUB_TYPE, PHASE, QUEUE_STATUS, SALE_TYPE } from "@/lib/labels";
import type { RadarSource } from "@/lib/source";
import type { HubDetail, HubDrone, InventoryRow, Selection } from "@/lib/types";
import { usePolled } from "@/lib/use-polled";
import {
  ChevronIcon,
  DroneIcon,
  HubTypeIcon,
  MailIcon,
  PhoneIcon,
  PowerIcon,
  PowerOffIcon,
  SnowflakeIcon,
} from "./icons";
import {
  Button,
  Chip,
  Note,
  PanelMessage,
  PanelShell,
  Pill,
  Section,
  Stat,
  TONE_TEXT,
} from "./ui";

const OUTAGE_MINUTES = [15, 30, 60, 120];

/**
 * RF-36 y CU-45: dejar la central sin energía por un tiempo, o devolvérsela.
 * Sus urgencias pasan a otra central y lo que tenía por cargar sale de su cola.
 */
function PowerSection({
  until,
  active,
  busy,
  blocked,
  onStart,
  onEnd,
}: {
  until: string | null;
  active: boolean;
  busy: boolean;
  blocked: string | null;
  onStart: (minutes: number) => void;
  onEnd: () => void;
}) {
  const [minutes, setMinutes] = useState(30);
  return (
    <Section title="Energía">
      {blocked && <p className="mb-3 text-[13px] text-muted">{blocked}</p>}
      {until ? (
        <div className="space-y-3">
          <Note tone="warn">
            Sin energía hasta las <span className="figures">{formatTime(until)}</span>. No autoriza ni
            carga; sus urgencias pasan a otra central.
          </Note>
          <Button busy={busy} disabled={blocked != null} className="w-full" onClick={onEnd}>
            <PowerIcon size={16} />
            Devolver la energía
          </Button>
        </div>
      ) : !active ? (
        <p className="text-[13px] text-muted">Una central suspendida no se apaga: ya no despacha.</p>
      ) : (
        <>
          <span className="text-[13px] text-muted">Apagón de</span>
          <div className="mb-3 mt-2 grid grid-cols-4 gap-1">
            {OUTAGE_MINUTES.map((value) => (
              <Chip key={value} selected={minutes === value} onClick={() => setMinutes(value)}>
                {value < 60 ? `${value} min` : `${value / 60} h`}
              </Chip>
            ))}
          </div>
          <Button
            tone="danger"
            busy={busy}
            disabled={blocked != null}
            className="w-full"
            onClick={() => onStart(minutes)}
          >
            <PowerOffIcon size={16} />
            Dejar sin energía
          </Button>
        </>
      )}
    </Section>
  );
}

const REFRESH_MS = 5_000;

const droneTone = {
  available: "good",
  in_mission: "info",
  maintenance: "warn",
  grounded: "bad",
  out_of_service: "bad",
} as const;

function DroneRow({ drone, onSelect }: { drone: HubDrone; onSelect: (s: Selection) => void }) {
  const flight = drone.flight;
  const tone = droneTone[drone.status];
  return (
    <li className="flex items-center gap-3 py-2.5">
      <DroneIcon size={19} className={`shrink-0 ${TONE_TEXT[tone]}`} />
      <div className="min-w-0 flex-1">
        <div className="figures truncate text-[14px] font-medium">{drone.identifier}</div>
        <div className="truncate text-[12px] text-muted">
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
          className="press flex h-7 shrink-0 items-center gap-0.5 rounded-md border border-accent/50 pl-2.5 pr-1.5 text-[12px] font-medium text-accent hover:bg-accent/12"
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
  return <span className="figures text-[12px] text-muted">{date}</span>;
}

function InventoryTable({ items }: { items: InventoryRow[] }) {
  if (!items.length) return <p className="text-[13px] text-muted">Sin existencias registradas.</p>;
  return (
    <ul className="divide-y divide-line">
      {items.map((item) => (
        <li key={item.id} className="flex items-center gap-3 py-2.5">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5 text-[14px] font-medium">
              {item.requiresColdChain && (
                <span title="Cadena de frío" className="shrink-0 text-info">
                  <SnowflakeIcon size={14} />
                </span>
              )}
              <span className="truncate">{item.name}</span>
            </div>
            <div className="truncate text-[12px] text-muted">
              Lote {item.lot} · {label(SALE_TYPE, item.saleType)}
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <div className="figures text-[14px] font-medium">{item.quantity}</div>
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
        <div className="grid grid-cols-4 gap-3">
          <Stat label="Libres" value={hub.fleet.available} tone="good" />
          <Stat label="En vuelo" value={hub.fleet.inMission} />
          <Stat label="Taller" value={hub.fleet.maintenance} tone={hub.fleet.maintenance ? "warn" : undefined} />
          <Stat label="Total" value={hub.fleet.total} />
        </div>
        {hub.drones.length > 0 && (
          <ul className="mt-4 divide-y divide-line border-t border-line">
            {hub.drones.map((drone) => (
              <DroneRow key={drone.id} drone={drone} onSelect={onSelect} />
            ))}
          </ul>
        )}
      </Section>

      <Section title="Pedidos en marcha">
        {queue.length ? (
          <div className="flex flex-wrap gap-x-6 gap-y-3">
            {queue.map(([status, count]) => (
              <span key={status} className="flex items-baseline gap-1.5 text-[13px]">
                <span className="figures text-[20px] font-medium">{count}</span>
                <span className="text-muted">{label(QUEUE_STATUS, status)}</span>
              </span>
            ))}
          </div>
        ) : (
          <p className="text-[13px] text-muted">No hay pedidos en marcha.</p>
        )}
      </Section>

      <Section
        title="Inventario"
        aside={
          <span className="text-[12px] text-muted">
            <span className="figures text-text">{hub.inventory.totalUnits}</span> unidades
          </span>
        }
      >
        {hub.inventory.quarantinedUnits > 0 && (
          <div className="mb-3">
            <Note tone="warn">
              {hub.inventory.quarantinedUnits} unidades en cuarentena (no están a la venta).
            </Note>
          </div>
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
  /** RF-36: sin energía hasta esta hora (del snapshot), o `null`. */
  outageUntil: string | null;
  busy: boolean;
  /** Por qué no se puede lanzar el apagón; `null` si se puede. */
  eventBlocked: string | null;
  onStartOutage: (hubId: string, minutes: number) => void;
  onEndOutage: (hubId: string) => void;
};

export function HubPanel({
  source,
  hubId,
  onSelect,
  outageUntil,
  busy,
  eventBlocked,
  onStartOutage,
  onEndOutage,
}: Props) {
  const load = useCallback(() => source.hub(hubId), [source, hubId]);
  const { data, error } = usePolled(load, hubId, REFRESH_MS);
  const close = () => onSelect(null);

  if (!data) {
    return (
      <PanelShell
        title="Central"
        icon={<HubTypeIcon type="" size={20} />}
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
      icon={<HubTypeIcon type={data.type} size={20} className={active ? "text-text" : "text-faint"} />}
      onClose={close}
      badge={
        <>
          <Pill tone="neutral" icon={<HubTypeIcon type={data.type} size={12} />}>
            {label(HUB_TYPE, data.type)}
          </Pill>
          <Pill tone={active ? "good" : "bad"}>{active ? "Activa" : "Suspendida"}</Pill>
          {outageUntil && (
            <Pill tone="warn" icon={<PowerOffIcon size={12} />}>
              Sin energía
            </Pill>
          )}
        </>
      }
    >
      <div className="flex flex-wrap gap-x-5 gap-y-2 px-5 py-4 text-[13px]">
        <a
          href={`tel:${data.contactPhone}`}
          className="figures flex items-center gap-2 text-muted transition-colors hover:text-text"
        >
          <PhoneIcon size={14} />
          {data.contactPhone}
        </a>
        {data.contactEmail && (
          <a
            href={`mailto:${data.contactEmail}`}
            className="flex min-w-0 items-center gap-2 text-muted transition-colors hover:text-text"
          >
            <MailIcon size={14} className="shrink-0" />
            <span className="truncate">{data.contactEmail}</span>
          </a>
        )}
        {error && (
          <p role="alert" className="w-full text-[12px] text-danger">
            Sin conexión: {error}
          </p>
        )}
      </div>
      <PowerSection
        until={outageUntil}
        active={active}
        busy={busy}
        blocked={eventBlocked}
        onStart={(minutes) => onStartOutage(hubId, minutes)}
        onEnd={() => onEndOutage(hubId)}
      />
      <HubBody hub={data} onSelect={onSelect} />
    </PanelShell>
  );
}
