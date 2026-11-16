"use client";

import { AIRSPACE_KIND, label, minutesLeft } from "@/lib/labels";
import { formatTime } from "@/lib/sim-time";
import type {
  AirspaceZone,
  DeliveryPoint,
  Selection,
  UnidentifiedContact,
} from "@/lib/types";
import { ClockIcon, PinIcon, ShieldIcon, UnknownIcon } from "./icons";
import { Button, Note, PanelShell, Pill, Section, Stat } from "./ui";

/** Qué significa cada tipo de zona para un vuelo. */
const ZONE_EFFECT: Record<AirspaceZone["kind"], string> = {
  aerodrome: "Anillo de 1,5 km alrededor del aeropuerto: no se vuela adentro y las rutas lo rodean.",
  prohibited: "No se vuela encima (CAI, batallón, cárcel, planta o pista agrícola): las rutas la rodean.",
  heliport: "Helipuerto: ninguna ruta lo cruza.",
};

/**
 * RF-43: la zona legal elegida en el mapa, con la norma que la sustenta y
 * de dónde salió el dato. No cambia en ejecución: es la carta de la región.
 */
export function AirspacePanel({
  zone,
  onSelect,
}: {
  zone: AirspaceZone | null;
  onSelect: (selection: Selection) => void;
}) {
  const close = () => onSelect(null);
  if (!zone) {
    return (
      <PanelShell title="Zona" onClose={close}>
        <p className="px-5 py-10 text-center text-[14px] text-muted">Esa zona ya no está en la carta.</p>
      </PanelShell>
    );
  }
  return (
    <PanelShell
      title={zone.name}
      subtitle={label(AIRSPACE_KIND, zone.kind)}
      icon={<ShieldIcon size={20} className={zone.blocking ? "text-danger" : "text-warning"} />}
      onClose={close}
      badge={
        <>
          <Pill tone={zone.blocking ? "bad" : "warn"}>{label(AIRSPACE_KIND, zone.kind)}</Pill>
          <Pill tone="neutral">{zone.blocking ? "No se vuela" : "Se vuela con condiciones"}</Pill>
        </>
      }
    >
      <Section title="Qué hace">
        <p className="text-[14px] leading-relaxed text-muted">{ZONE_EFFECT[zone.kind]}</p>
      </Section>
      <Section title="Norma">
        <p className="text-[14px] leading-relaxed text-text">{zone.legalBasis}</p>
        <p className="mt-3 text-[13px] text-muted">Fuente: {zone.source}</p>
      </Section>
    </PanelShell>
  );
}

/**
 * RF-45: el punto de entrega elegido. El interruptor lo activa o lo
 * desactiva, igual que el apagón de una central: no es un formulario.
 */
export function PointPanel({
  point,
  hubName,
  busy,
  blocked,
  onToggle,
  onSelect,
}: {
  point: DeliveryPoint | null;
  /** El nodo que lo atiende. */
  hubName: string | null;
  busy: boolean;
  /** Por qué no se puede cambiar; `null` si se puede. */
  blocked: string | null;
  onToggle: (id: string, active: boolean) => void;
  onSelect: (selection: Selection) => void;
}) {
  const close = () => onSelect(null);
  if (!point) {
    return (
      <PanelShell title="Punto de entrega" onClose={close}>
        <p className="px-5 py-10 text-center text-[14px] text-muted">Ese punto ya no existe.</p>
      </PanelShell>
    );
  }
  return (
    <PanelShell
      title={point.name}
      subtitle={point.municipality}
      icon={<PinIcon size={20} className={point.available ? "text-success" : "text-faint"} />}
      onClose={close}
      badge={
        <>
          <Pill tone="neutral">Punto de entrega</Pill>
          <Pill tone={point.available ? "good" : "bad"}>
            {point.available ? "Disponible" : point.active ? "Su nodo no está activo" : "Inactivo"}
          </Pill>
        </>
      }
    >
      <div className="grid grid-cols-2 gap-2.5 px-5 py-4">
        <Stat label="Elevación" value={Math.round(point.elevationM)} unit="m" />
        <Stat
          label="Lo atiende"
          value={<span className="font-sans text-[15px]">{hubName ?? "Sin nodo"}</span>}
        />
      </div>
      <Section title="Estado">
        {blocked && <p className="mb-3 text-[13px] text-muted">{blocked}</p>}
        <div className="mb-3">
          <Note tone={point.active ? "neutral" : "warn"}>
            {point.active
              ? "Activo: los solicitantes cercanos lo ven y pueden pedir hacia él."
              : "Inactivo: no sale en la lista de quien pide y las urgencias no llegan aquí."}
          </Note>
        </div>
        <Button
          tone={point.active ? "danger" : undefined}
          busy={busy}
          disabled={blocked != null}
          className="w-full"
          onClick={() => onToggle(point.id, !point.active)}
        >
          {point.active ? "Desactivar el punto" : "Activar el punto"}
        </Button>
      </Section>
    </PanelShell>
  );
}

/**
 * RF-36 y RF-48: un dron sin identificación que cruza la región. AirDrop no
 * actúa contra él: lo muestra y avisa si pasa cerca de un corredor propio.
 */
export function ContactPanel({
  contact,
  now,
  onSelect,
}: {
  contact: UnidentifiedContact | null;
  /** Hora simulada (ms). */
  now: number;
  onSelect: (selection: Selection) => void;
}) {
  const close = () => onSelect(null);
  if (!contact) {
    return (
      <PanelShell title="Dron no identificado" onClose={close}>
        <p className="px-5 py-10 text-center text-[14px] text-muted">Ya salió de la región.</p>
      </PanelShell>
    );
  }
  return (
    <PanelShell
      title="Dron no identificado"
      subtitle={`Sale a las ${formatTime(contact.endsAt)}`}
      icon={<UnknownIcon size={20} className="text-magenta" />}
      onClose={close}
      badge={
        <>
          <Pill tone="bad">Sin identificación remota</Pill>
          <Pill tone="neutral" icon={<ClockIcon size={12} />}>
            {minutesLeft(contact.endsAt, now)} min
          </Pill>
        </>
      }
    >
      <div className="grid grid-cols-2 gap-2.5 px-5 py-4">
        <Stat label="Velocidad" value={Math.round(contact.speedKmh)} unit="km/h" />
        <Stat label="Quedan" value={minutesLeft(contact.endsAt, now)} unit="min" />
      </div>
      {contact.nearIdentifier && (
        <div className="px-5 py-4">
          <Note tone="bad">Cerca del corredor de {contact.nearIdentifier}.</Note>
        </div>
      )}
      <Section title="Qué hace AirDrop">
        <p className="text-[14px] leading-relaxed text-muted">
          AirDrop no actúa contra él: solo lo muestra y avisa. No tiene matrícula ni manifiesto
          porque no es de la red.
        </p>
      </Section>
    </PanelShell>
  );
}
