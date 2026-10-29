"use client";

import { formatEta, label, ORDER_STATUS, PHASE } from "@/lib/labels";
import type { FlightDetail, RadarFlight, Selection } from "@/lib/types";
import {
  AlertIcon,
  AltitudeIcon,
  BatteryIcon,
  ChevronIcon,
  ClockIcon,
  DroneIcon,
  HubIcon,
  PackageIcon,
  PhaseIcon,
  RouteIcon,
  SnowflakeIcon,
  SpeedIcon,
  ThermometerIcon,
} from "./icons";
import { IconTile, PanelMessage, PanelShell, Pill, Section, Stat } from "./ui";

/** La cadena de frío vale entre 2 y 8 °C (RF-17). */
const outOfRange = (t: number | null) => t != null && (t < 2 || t > 8);

const hasAlert = (flight: RadarFlight) =>
  flight.alerts.battery || flight.alerts.failure || flight.alerts.coldChain;

function Battery({ percent }: { percent: number | null }) {
  const value = percent ?? 0;
  const tone = value < 20 ? "text-danger" : value < 40 ? "text-warning" : "text-accent";
  const bar = value < 20 ? "bg-danger" : value < 40 ? "bg-warning" : "bg-accent-gradient";
  return (
    <div className="col-span-2 rounded-2xl border border-glass-border bg-glass p-3.5">
      <div className="flex items-center justify-between">
        <span className="flex items-center gap-1.5 text-muted">
          <BatteryIcon size={14} />
          <span className="eyebrow !tracking-[0.1em]">Batería</span>
        </span>
        <span className={`text-2xl font-semibold leading-none tabular-nums ${tone}`}>
          {percent ?? "—"}
          <span className="ml-1 text-xs font-medium text-muted">%</span>
        </span>
      </div>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-sunk">
        <div
          className={`h-full rounded-full transition-[width] duration-700 ${bar}`}
          style={{ width: `${value}%` }}
        />
      </div>
    </div>
  );
}

function Alerts({ flight }: { flight: RadarFlight }) {
  const items = [
    flight.alerts.battery && "Batería crítica",
    flight.alerts.failure && "Falla de batería",
    flight.alerts.coldChain && "Temperatura fuera de rango (2 a 8 °C)",
  ].filter(Boolean) as string[];
  if (!items.length) return null;
  return (
    <Section title="Alertas" icon={<AlertIcon size={14} />}>
      <ul className="space-y-2">
        {items.map((text) => (
          <li
            key={text}
            className="flex items-center gap-2.5 rounded-xl border border-danger/30 bg-danger/10 px-3 py-2.5 text-sm font-medium text-danger"
          >
            <AlertIcon size={16} />
            {text}
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Route({ detail, flight }: { detail: FlightDetail | null; flight: RadarFlight }) {
  const destination =
    detail?.destinationHub?.name ??
    (flight.destinationKind === "person" ? "Entrega a una persona" : "—");
  return (
    <Section title="Ruta" icon={<RouteIcon size={14} />}>
      <ol className="relative space-y-4 pl-6">
        <span className="absolute bottom-2 left-[5px] top-2 w-px bg-linear-to-b from-accent to-warning/70" />
        <li className="relative">
          <span className="absolute -left-6 top-1 size-[11px] rounded-full border-2 border-accent bg-backdrop" />
          <div className="eyebrow !text-[10px]">Origen</div>
          <div className="truncate text-sm font-medium">{detail?.originHub?.name ?? "—"}</div>
        </li>
        <li className="relative">
          <span className="absolute -left-6 top-1 size-[11px] rounded-full bg-accent-gradient" />
          <div className="eyebrow !text-[10px]">Destino</div>
          <div className="truncate text-sm font-medium">{destination}</div>
        </li>
      </ol>
      <div className="mt-4 grid grid-cols-2 gap-2">
        <Stat label="Distancia" value={detail?.route?.distanceKm ?? "—"} unit="km" />
        <Stat label="Altitud de ruta" value={detail?.route?.altitudeM ?? "—"} unit="m" />
      </div>
      <div className="mt-3 flex gap-5 text-xs text-muted">
        <span className="flex items-center gap-2">
          <span className="h-[3px] w-6 rounded-full bg-accent" /> Ida
        </span>
        <span className="flex items-center gap-2">
          <span className="w-6 border-t-[3px] border-dashed border-warning" /> Regreso
        </span>
      </div>
    </Section>
  );
}

type Props = {
  /** Ruta y nombres; llega por REST y se refresca cada pocos segundos. */
  detail: FlightDetail | null;
  error: string | null;
  /** El vuelo en vivo (socket). */
  live: RadarFlight | undefined;
  onSelect: (selection: Selection) => void;
};

export function FlightPanel({ detail, error, live, onSelect }: Props) {
  const flight = live ?? detail?.flight ?? null;
  const close = () => onSelect(null);

  if (!flight) {
    return (
      <PanelShell
        title="Vuelo"
        icon={<IconTile><DroneIcon size={24} /></IconTile>}
        onClose={close}
      >
        <PanelMessage failed={Boolean(error)}>{error ?? "Buscando el vuelo…"}</PanelMessage>
      </PanelShell>
    );
  }
  const returning = flight.leg === "return";
  const alert = hasAlert(flight);
  return (
    <PanelShell
      title={flight.identifier}
      subtitle={label(ORDER_STATUS, flight.orderStatus)}
      icon={
        <IconTile tone={alert ? "bad" : returning ? "warn" : "info"}>
          <DroneIcon size={24} />
        </IconTile>
      }
      onClose={close}
      badge={
        <>
          <Pill tone={returning ? "warn" : "info"}>{returning ? "Regreso" : "Ida"}</Pill>
          <Pill tone={flight.missionType === "emergency" ? "bad" : "neutral"}>
            {flight.missionType === "emergency" ? "Urgencia" : "Programado"}
          </Pill>
          {flight.requiresColdChain && (
            <Pill tone="info" icon={<SnowflakeIcon size={12} />}>
              Cadena de frío
            </Pill>
          )}
        </>
      }
    >
      <div className="grid grid-cols-2 gap-2 px-5 py-4">
        <Battery percent={flight.batteryPercent} />
        <Stat label="ETA" icon={<ClockIcon size={14} />} value={formatEta(flight.etaSeconds)} />
        <Stat
          label="Velocidad"
          icon={<SpeedIcon size={14} />}
          value={flight.speedKmh != null ? Math.round(flight.speedKmh) : "—"}
          unit="km/h"
        />
        <Stat
          label="Altitud"
          icon={<AltitudeIcon size={14} />}
          value={flight.altitudeM != null ? Math.round(flight.altitudeM) : "—"}
          unit="m"
        />
        <Stat
          label="Fase"
          icon={<PhaseIcon size={14} />}
          value={<span className="text-base">{label(PHASE, flight.phase)}</span>}
        />
        {flight.temperatureC != null && (
          <Stat
            label="Temperatura"
            icon={<ThermometerIcon size={14} />}
            value={flight.temperatureC.toFixed(1)}
            unit="°C"
            tone={outOfRange(flight.temperatureC) ? "bad" : undefined}
          />
        )}
      </div>

      <Alerts flight={flight} />

      <Section title="Carga" icon={<PackageIcon size={14} />}>
        <div className="flex items-center gap-3 rounded-2xl border border-glass-border bg-glass px-3.5 py-3 text-sm">
          <span className="text-2xl font-semibold tabular-nums">{flight.quantity}</span>
          <span className="text-muted">
            unidades
            {flight.medicationName ? (
              <>
                {" de "}
                <span className="font-medium text-text">{flight.medicationName}</span>
              </>
            ) : (
              " · contenido reservado"
            )}
          </span>
        </div>
      </Section>

      <Route detail={detail} flight={flight} />

      {detail?.originHub && (
        <div className="px-5 py-4">
          <button
            type="button"
            onClick={() => onSelect({ kind: "hub", id: detail.originHub!.id })}
            className="flex w-full items-center gap-3 rounded-2xl border border-glass-border bg-glass px-4 py-3 text-left text-sm font-semibold transition hover:border-accent/40 hover:bg-accent/10 focus-visible:outline-2 focus-visible:outline-accent"
          >
            <HubIcon size={18} className="text-accent" />
            <span className="flex-1">Ver central de origen</span>
            <ChevronIcon size={16} className="text-muted" />
          </button>
        </div>
      )}
      {error && (
        <p role="alert" className="px-5 py-3 text-xs text-danger">
          Sin conexión: {error}
        </p>
      )}
    </PanelShell>
  );
}
