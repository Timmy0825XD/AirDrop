"use client";

import { formatEta, label, ORDER_STATUS, PHASE } from "@/lib/labels";
import type { FlightDetail, RadarFlight, Selection } from "@/lib/types";
import { PanelMessage, PanelShell, Pill, Section, Stat } from "./ui";

/** La cadena de frío vale entre 2 y 8 °C (RF-17). */
const outOfRange = (t: number | null) => t != null && (t < 2 || t > 8);

function Battery({ percent }: { percent: number | null }) {
  const value = percent ?? 0;
  const color = value < 20 ? "bg-alert" : value < 40 ? "bg-returning" : "bg-outbound";
  return (
    <div className="rounded-xl border border-line bg-panel-2/60 p-3">
      <div className="flex items-baseline justify-between">
        <span className="text-[10px] font-semibold uppercase tracking-wider text-muted">Batería</span>
        <span className="font-mono text-xl font-semibold">{percent ?? "—"}<span className="ml-1 text-xs font-normal text-muted">%</span></span>
      </div>
      <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-ink">
        <div className={`h-full rounded-full transition-all duration-700 ${color}`} style={{ width: `${value}%` }} />
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
    <Section title="Alertas">
      <ul className="space-y-2">
        {items.map((text) => (
          <li key={text} className="rounded-lg bg-alert/10 px-3 py-2 text-sm text-alert">
            ⚠ {text}
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
    <Section title="Ruta">
      <div className="space-y-1 text-sm">
        <div>
          <span className="text-muted">Origen · </span>
          {detail?.originHub?.name ?? "—"}
        </div>
        <div>
          <span className="text-muted">Destino · </span>
          {destination}
        </div>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <Stat label="Distancia" value={detail?.route?.distanceKm ?? "—"} unit="km" />
        <Stat label="Altitud de ruta" value={detail?.route?.altitudeM ?? "—"} unit="m" />
      </div>
      <div className="mt-3 flex gap-4 text-xs text-muted">
        <span className="flex items-center gap-1.5">
          <span className="h-0.5 w-5 bg-outbound" /> Ida
        </span>
        <span className="flex items-center gap-1.5">
          <span className="h-0.5 w-5 border-t-2 border-dashed border-returning" /> Regreso
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
      <PanelShell title="Vuelo" onClose={close}>
        <PanelMessage>{error ?? "Buscando el vuelo…"}</PanelMessage>
      </PanelShell>
    );
  }
  const returning = flight.leg === "return";
  return (
    <PanelShell
      title={flight.identifier}
      subtitle={label(ORDER_STATUS, flight.orderStatus)}
      onClose={close}
      badge={
        <>
          <Pill tone={returning ? "warn" : "good"}>{returning ? "Regreso" : "Ida"}</Pill>
          <Pill tone={flight.missionType === "emergency" ? "bad" : "neutral"}>
            {flight.missionType === "emergency" ? "Urgencia" : "Programado"}
          </Pill>
          {flight.requiresColdChain && <Pill tone="info">❄ Cadena de frío</Pill>}
        </>
      }
    >
      <div className="grid grid-cols-2 gap-2 px-5 pb-4">
        <Battery percent={flight.batteryPercent} />
        <Stat label="ETA" value={formatEta(flight.etaSeconds)} />
        <Stat label="Velocidad" value={flight.speedKmh != null ? Math.round(flight.speedKmh) : "—"} unit="km/h" />
        <Stat label="Altitud" value={flight.altitudeM != null ? Math.round(flight.altitudeM) : "—"} unit="m" />
        <Stat label="Fase" value={<span className="text-base">{label(PHASE, flight.phase)}</span>} />
        {flight.temperatureC != null && (
          <Stat
            label="Temperatura"
            value={flight.temperatureC.toFixed(1)}
            unit="°C"
            tone={outOfRange(flight.temperatureC) ? "bad" : undefined}
          />
        )}
      </div>

      <Alerts flight={flight} />

      <Section title="Carga">
        <div className="text-sm">
          <span className="font-mono font-semibold">{flight.quantity}</span> unidades
          {flight.medicationName ? ` de ${flight.medicationName}` : " · contenido reservado"}
        </div>
      </Section>

      <Route detail={detail} flight={flight} />

      {detail?.originHub && (
        <div className="border-t border-line px-5 py-4">
          <button
            type="button"
            onClick={() => onSelect({ kind: "hub", id: detail.originHub!.id })}
            className="w-full rounded-xl border border-line py-2 text-sm font-medium text-hub transition hover:bg-panel-2 focus-visible:outline-2 focus-visible:outline-hub"
          >
            Ver central de origen
          </button>
        </div>
      )}
      {error && <p className="px-5 pb-4 text-xs text-alert">Sin conexión: {error}</p>}
    </PanelShell>
  );
}
