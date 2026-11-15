"use client";

import { AIRSPACE_KIND, label } from "@/lib/labels";
import type { AirspaceZone, DeliveryPoint, Selection } from "@/lib/types";
import { PinIcon, ShieldIcon } from "./icons";
import { Button, Note, PanelShell, Pill, Section, Stat } from "./ui";

/** Qué significa cada tipo de zona para un vuelo. */
const ZONE_EFFECT: Record<AirspaceZone["kind"], string> = {
  aerodrome: "Dentro del anillo no se vuela: las rutas lo rodean y ninguna central puede quedar adentro.",
  prohibited: "Zona prohibida con su margen: ninguna ruta la cruza.",
  heliport: "Margen de un helipuerto: ninguna ruta lo cruza.",
  urban: "Zona urbana: no se entrega con dron. Quien pide desde aquí ve la alternativa terrestre.",
  coordinated: "Zona coordinada: solo se entra por el corredor pactado, hasta su punto de entrega.",
  caution: "Precaución: se puede volar, con atención a la pista.",
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
      {zone.sites.length > 0 && (
        <Section title="Destinos pactados">
          <ul className="space-y-1.5 text-[14px] text-muted">
            {zone.sites.map((site) => (
              <li key={site.name}>{site.name}</li>
            ))}
          </ul>
        </Section>
      )}
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
          {point.corridor && <Pill tone="warn">Corredor pactado</Pill>}
        </>
      }
    >
      <div className="grid grid-cols-2 gap-x-4 gap-y-5 px-5 py-5">
        <Stat label="Elevación" value={Math.round(point.elevationM)} unit="m" />
        <Stat
          label="Lo atiende"
          value={<span className="font-sans text-[15px]">{hubName ?? "Sin nodo"}</span>}
        />
      </div>
      {point.corridor && (
        <Section title="Corredor pactado">
          <p className="text-[14px] leading-relaxed text-muted">
            Está en {point.corridor.zoneName}: el dron entra solo por el corredor acordado con la
            comunidad.
          </p>
        </Section>
      )}
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
