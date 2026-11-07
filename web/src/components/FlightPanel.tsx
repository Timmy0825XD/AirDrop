"use client";

import { formatEta, label, ORDER_STATUS, PHASE } from "@/lib/labels";
import type { ConsoleIncidentKind, FlightDetail, RadarFlight, Selection } from "@/lib/types";
import { IncidentActions } from "./IncidentActions";
import { AlertIcon, ChevronIcon, DroneIcon, HubIcon, LinkOffIcon, SnowflakeIcon } from "./icons";
import { PanelMessage, PanelShell, Pill, Section, Stat } from "./ui";

/** La cadena de frío vale entre 2 y 8 °C (RF-17). */
const outOfRange = (t: number | null) => t != null && (t < 2 || t > 8);

const hasAlert = (flight: RadarFlight) =>
  flight.alerts.battery || flight.alerts.failure || flight.alerts.coldChain;

/** La batería: la cifra grande y una barra fina con el tono de su nivel. */
function Battery({ percent }: { percent: number | null }) {
  const value = percent ?? 0;
  const tone = value < 20 ? "text-danger" : value < 40 ? "text-warning" : "text-text";
  const bar = value < 20 ? "bg-danger" : value < 40 ? "bg-warning" : "bg-success";
  return (
    <div className="col-span-2">
      <div className="flex items-baseline justify-between">
        <span className="text-[12px] text-muted">Batería</span>
        <span className={`figures text-[28px] font-medium leading-none ${tone}`}>
          {percent ?? "—"}
          <span className="ml-0.5 font-sans text-[13px] font-normal text-muted">%</span>
        </span>
      </div>
      <div className="mt-2.5 h-1.5 overflow-hidden rounded-full bg-raised">
        <div
          className={`h-full rounded-full transition-[width] duration-700 ease-out ${bar}`}
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
    <Section title="Alertas">
      <ul className="space-y-1.5">
        {items.map((text) => (
          <li
            key={text}
            className="flex items-center gap-2.5 rounded-lg border border-danger/40 bg-danger/8 px-3 py-2.5 text-[13px] font-medium text-danger"
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
    <Section title="Ruta">
      <ol className="relative space-y-3.5 pl-5">
        <span className="absolute bottom-2 left-[3.5px] top-2 w-px bg-line-strong" />
        <li className="relative">
          <span className="absolute -left-5 top-[5px] size-2 rounded-full border-[1.5px] border-muted bg-panel" />
          <div className="text-[12px] text-muted">Origen</div>
          <div className="truncate text-[14px] font-medium">{detail?.originHub?.name ?? "—"}</div>
        </li>
        <li className="relative">
          <span className="absolute -left-5 top-[5px] size-2 rounded-full bg-accent" />
          <div className="text-[12px] text-muted">Destino</div>
          <div className="truncate text-[14px] font-medium">{destination}</div>
        </li>
      </ol>
      <div className="mt-5 grid grid-cols-2 gap-4">
        <Stat label="Distancia" value={detail?.route?.distanceKm ?? "—"} unit="km" />
        <Stat label="Altitud de ruta" value={detail?.route?.altitudeM ?? "—"} unit="m" />
      </div>
      <div className="mt-4 flex flex-wrap gap-x-5 gap-y-2 text-[12px] text-muted">
        <span className="flex items-center gap-2">
          <span className="h-0.5 w-6 rounded-full bg-accent" /> Ida
        </span>
        <span className="flex items-center gap-2">
          <span className="w-6 border-t-2 border-dashed border-warning" /> Regreso
        </span>
        {(detail?.previousRoute || detail?.previousReturnRoute) && (
          // RF-33: cambió en el aire; la de antes queda punteada.
          <span className="flex items-center gap-2">
            <span className="w-6 border-t-2 border-dotted border-muted" /> Ruta anterior
          </span>
        )}
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
  /** CU-38: lanzar un incidente sobre este dron. */
  busy: boolean;
  incidentBlocked: string | null;
  onIncident: (droneId: string, kind: ConsoleIncidentKind) => void;
};

export function FlightPanel({
  detail,
  error,
  live,
  onSelect,
  busy,
  incidentBlocked,
  onIncident,
}: Props) {
  const flight = live ?? detail?.flight ?? null;
  const close = () => onSelect(null);

  if (!flight) {
    return (
      <PanelShell title="Vuelo" icon={<DroneIcon size={20} />} onClose={close}>
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
        <DroneIcon
          size={20}
          className={alert ? "text-danger" : returning ? "text-warning" : "text-text"}
        />
      }
      onClose={close}
      badge={
        <>
          <Pill tone={returning ? "warn" : "neutral"}>{returning ? "Regreso" : "Ida"}</Pill>
          <Pill tone={flight.missionType === "emergency" ? "bad" : "neutral"}>
            {flight.missionType === "emergency" ? "Urgencia" : "Programado"}
          </Pill>
          {flight.requiresColdChain && (
            <Pill tone="info" icon={<SnowflakeIcon size={12} />}>
              Cadena de frío
            </Pill>
          )}
          {flight.linkLost && (
            // RF-34: vuelve solo; lo que se ve es su posición estimada.
            <Pill tone="warn" icon={<LinkOffIcon size={12} />}>
              Sin enlace · posición estimada
            </Pill>
          )}
        </>
      }
    >
      <div className="grid grid-cols-2 gap-x-4 gap-y-5 px-5 py-5">
        <Battery percent={flight.batteryPercent} />
        <Stat label="Llega en" value={formatEta(flight.etaSeconds)} />
        <Stat
          label="Velocidad"
          value={flight.speedKmh != null ? Math.round(flight.speedKmh) : "—"}
          unit="km/h"
        />
        <Stat
          label="Altitud"
          value={flight.altitudeM != null ? Math.round(flight.altitudeM) : "—"}
          unit="m"
        />
        <Stat
          label="Fase"
          value={<span className="font-sans text-[17px]">{label(PHASE, flight.phase)}</span>}
        />
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
        <p className="text-[14px] text-muted">
          <span className="figures mr-1.5 text-[20px] font-medium text-text">{flight.quantity}</span>
          unidades
          {flight.medicationName ? (
            <>
              {" de "}
              <span className="text-text">{flight.medicationName}</span>
            </>
          ) : (
            " · contenido reservado"
          )}
        </p>
      </Section>

      <Route detail={detail} flight={flight} />

      <IncidentActions
        cold={flight.requiresColdChain && flight.leg !== "return"}
        busy={busy}
        disabledReason={incidentBlocked}
        onLaunch={(kind) => onIncident(flight.droneId, kind)}
      />

      {detail?.originHub && (
        <div className="px-3 py-3">
          <button
            type="button"
            onClick={() => onSelect({ kind: "hub", id: detail.originHub!.id })}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[14px] font-medium transition-colors hover:bg-hover"
          >
            <HubIcon size={17} className="text-muted" />
            <span className="flex-1">Ver la central de origen</span>
            <ChevronIcon size={15} className="text-faint" />
          </button>
        </div>
      )}
      {error && (
        <p role="alert" className="px-5 py-3 text-[12px] text-danger">
          Sin conexión: {error}
        </p>
      )}
    </PanelShell>
  );
}
