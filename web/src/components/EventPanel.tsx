"use client";

import { compassOf } from "@/lib/geo";
import { WEATHER_KIND, minutesLeft } from "@/lib/labels";
import { formatTime } from "@/lib/sim-time";
import type { Geofence, Selection, WeatherCell } from "@/lib/types";
import { ClockIcon, RainIcon, StormIcon, WindIcon, ZoneIcon } from "./icons";
import { IconTile, PanelShell, Pill, PrimaryButton, Section, Stat } from "./ui";

const EFFECT: Record<WeatherCell["kind"], string> = {
  wind: "Solo cuenta la parte del viento a lo largo del tramo: en contra frena al dron y gasta más; a favor, al revés. Sobre 15 m/s sostenidos o 20 m/s en ráfagas no se vuela.",
  rain: "Se vuela con un 10 % más de consumo en crucero dentro de la celda.",
  storm: "Zona no volable mientras dure: las rutas la rodean y un dron en el aire que la tiene adelante cambia de camino o vuelve.",
};

/**
 * RF-32 y RF-36: el clima o la geovalla temporal elegidos en el mapa, con lo
 * que hacen, hasta cuándo rigen y el botón para terminarlos antes.
 */
export function EventPanel({
  weather,
  zone,
  now,
  busy,
  canEnd,
  onEnd,
  onSelect,
}: {
  weather: WeatherCell | null;
  zone: Geofence | null;
  now: number;
  busy: boolean;
  canEnd: boolean;
  onEnd: () => void;
  onSelect: (selection: Selection) => void;
}) {
  const close = () => onSelect(null);

  if (weather) {
    const storm = weather.kind === "storm";
    const icon =
      weather.kind === "wind" ? <WindIcon size={24} /> : storm ? <StormIcon size={24} /> : <RainIcon size={24} />;
    return (
      <PanelShell
        title={WEATHER_KIND[weather.kind]}
        subtitle={`Hasta las ${formatTime(weather.endsAt)}`}
        icon={<IconTile tone={storm ? "bad" : "info"}>{icon}</IconTile>}
        onClose={close}
        badge={
          <>
            <Pill tone={storm ? "bad" : "info"}>Clima simulado</Pill>
            <Pill tone="neutral" icon={<ClockIcon size={12} />}>
              {minutesLeft(weather.endsAt, now)} min
            </Pill>
          </>
        }
      >
        <div className="grid grid-cols-2 gap-2 px-5 py-4">
          <Stat label="Radio" value={weather.radiusKm.toLocaleString("es-CO")} unit="km" />
          <Stat label="Quedan" value={minutesLeft(weather.endsAt, now)} unit="min" />
          {weather.kind === "wind" && weather.windSpeedMs != null && (
            <>
              <Stat
                label="Fuerza"
                value={Math.round(weather.windSpeedMs)}
                unit="m/s"
                tone={weather.windSpeedMs > 15 ? "warn" : undefined}
              />
              <Stat
                label="Sopla del"
                value={<span className="text-xl">{compassOf(weather.windFromDeg ?? 0).long}</span>}
              />
            </>
          )}
        </div>
        <Section title="Qué hace">
          <p className="text-[15px] leading-relaxed text-muted">{EFFECT[weather.kind]}</p>
        </Section>
        <div className="px-5 py-4">
          <PrimaryButton tone="danger" busy={busy} disabled={!canEnd} className="w-full" onClick={onEnd}>
            Terminar ahora
          </PrimaryButton>
        </div>
      </PanelShell>
    );
  }

  if (zone?.expiresAt) {
    return (
      <PanelShell
        title={zone.name}
        subtitle={`Vence a las ${formatTime(zone.expiresAt)}`}
        icon={
          <IconTile tone="warn">
            <ZoneIcon size={24} />
          </IconTile>
        }
        onClose={close}
        badge={
          <>
            <Pill tone="warn">Geovalla temporal</Pill>
            <Pill tone="neutral" icon={<ClockIcon size={12} />}>
              {minutesLeft(zone.expiresAt, now)} min
            </Pill>
          </>
        }
      >
        <Section title="Qué hace">
          <p className="text-[15px] leading-relaxed text-muted">
            Mientras dure cuenta como cualquier geovalla: las rutas la rodean y un dron en el aire que
            la tiene adelante cambia de camino. Al vencer desaparece sola.
          </p>
          <p className="mt-3 text-sm text-muted">Motivo: {zone.reason}</p>
        </Section>
        <div className="px-5 py-4">
          <PrimaryButton tone="danger" busy={busy} disabled={!canEnd} className="w-full" onClick={onEnd}>
            Levantar la zona
          </PrimaryButton>
        </div>
      </PanelShell>
    );
  }

  return (
    <PanelShell title="Evento" onClose={close}>
      <p className="px-5 py-10 text-center text-[15px] text-muted">Este evento ya terminó.</p>
    </PanelShell>
  );
}
