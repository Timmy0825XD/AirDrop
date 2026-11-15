"use client";

import { DRONE_KIND, REMOTE_ID_STATUS, label } from "@/lib/labels";
import { formatTime } from "@/lib/sim-time";
import type { RadarManifest, RemoteId } from "@/lib/types";
import { Note, Pill, Section } from "./ui";

const STATUS_TONE = {
  mission: "good",
  returning: "warn",
  link_lost: "warn",
  emergency: "bad",
} as const;

/** Una fila "etiqueta … valor" de los bloques del vuelo. */
function Row({ name, value }: { name: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-1.5 text-[14px]">
      <dt className="shrink-0 text-muted">{name}</dt>
      <dd className="figures min-w-0 truncate text-right text-text">{value}</dd>
    </div>
  );
}

/**
 * RF-48: lo que el dron anuncia de sí mismo en cada lectura (matrícula,
 * operador, tipo, manifiesto vigente y estado). Una lectura vieja no lo trae.
 */
export function RemoteIdSection({ remoteId }: { remoteId: RemoteId | null | undefined }) {
  if (!remoteId) return null;
  return (
    <Section
      title="Identificación"
      aside={
        <Pill tone={STATUS_TONE[remoteId.status] ?? "neutral"}>
          {label(REMOTE_ID_STATUS, remoteId.status)}
        </Pill>
      }
    >
      <dl>
        <Row name="Matrícula" value={remoteId.registration} />
        <Row name="Operador" value={remoteId.operator} />
        <Row name="Tipo" value={remoteId.type} />
        <Row name="Manifiesto" value={remoteId.manifestNumber ?? "Sin carga"} />
      </dl>
      {remoteId.status === "link_lost" && (
        <div className="mt-3">
          <Note tone="warn">
            Sin enlace: espera unos 30 s en el mismo punto y después sigue su misión o vuelve.
          </Note>
        </div>
      )}
    </Section>
  );
}

/**
 * RF-47: el manifiesto de carga del vuelo. En una entrega a una persona el
 * backend no manda el medicamento (la consola se proyecta): se dice
 * "Medicamento reservado" y nunca se pide la versión completa.
 */
export function ManifestSection({ manifest }: { manifest: RadarManifest | null | undefined }) {
  if (!manifest) return null;
  return (
    <Section
      title={`Manifiesto ${manifest.number}`}
      aside={<span className="figures text-[12px] text-muted">{formatTime(manifest.issuedAt)}</span>}
    >
      <dl>
        <Row
          name="Dron"
          value={`${manifest.drone.identifier} · ${label(DRONE_KIND, manifest.drone.kind)}`}
        />
        <Row name="Sale de" value={manifest.origin.name} />
        <Row name="Llega a" value={manifest.destination} />
        <Row
          name="Peso"
          value={`${manifest.payloadKg.toLocaleString("es-CO", { maximumFractionDigits: 2 })} kg`}
        />
        {manifest.coldRange && <Row name="Frío" value={`Con compartimento · ${manifest.coldRange}`} />}
        <Row name="Autorizó" value={manifest.authorizedBy.name} />
      </dl>
      <ul className="mt-3 space-y-2 border-t border-line pt-3 text-[13px] text-muted">
        {manifest.items.map((item) => (
          <li key={item.lot}>
            <span className="text-text">{item.medicationName ?? "Medicamento reservado"}</span>
            {" · "}
            <span className="figures">{item.quantity}</span> und. · lote{" "}
            <span className="figures">{item.lot}</span> · vence{" "}
            <span className="figures">{item.expiresOn}</span>
          </li>
        ))}
      </ul>
      {manifest.voidedAt && (
        <div className="mt-3">
          <Note tone="warn">Anulado{manifest.voidReason ? `: ${manifest.voidReason}` : ""}.</Note>
        </div>
      )}
    </Section>
  );
}
