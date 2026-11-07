"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import type { ActorsState, ChaosIntensity, ChaosState, GeneratedKind } from "@/lib/types";
import { BotIcon, ChaosIcon, PackageIcon, SurgeIcon } from "./icons";

const INTENSITIES: Array<{ value: ChaosIntensity; label: string; every: string }> = [
  { value: "low", label: "Baja", every: "~15 min" },
  { value: "medium", label: "Media", every: "~8 min" },
  { value: "high", label: "Alta", every: "~4 min" },
];

type Props = {
  actors: ActorsState;
  chaos: ChaosState;
  busy: boolean;
  onChange: (change: Partial<ActorsState>) => void;
  onChaos: (change: Partial<ChaosState>) => void;
  onGenerate: (kind: GeneratedKind) => void;
};

/**
 * RF-37, CU-39 y RF-38: los actores simulados y el modo caos. Un botón de la
 * barra abre la tarjeta con los interruptores y el generador a pedido. El
 * pico de urgencias va en la barra de eventos, porque se elige sobre el mapa.
 * Con el caos encendido el botón se pone rojo y lo dice, para verlo en la TV.
 */
export function ActorsMenu({ actors, chaos, busy, onChange, onChaos, onGenerate }: Props) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const on = Number(actors.autoDispatcher) + Number(actors.orderFlow);
  const chaosLabel = INTENSITIES.find((item) => item.value === chaos.intensity)?.label ?? "";

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    const onDown = (event: PointerEvent) => {
      if (box.current && !box.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onDown);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onDown);
    };
  }, [open]);

  return (
    <div ref={box} className="relative hidden md:block">
      <button
        type="button"
        onClick={() => setOpen((value) => !value)}
        aria-expanded={open}
        aria-haspopup="dialog"
        title="Actores simulados y modo caos"
        className={`press flex h-10 items-center gap-2 rounded-lg border px-3 text-[14px] font-medium ${
          chaos.enabled
            ? "border-danger/55 bg-danger/12 text-danger"
            : open || on > 0
              ? "border-accent/50 bg-accent/12 text-accent"
              : "border-line bg-panel text-muted hover:border-line-strong hover:bg-hover hover:text-text"
        }`}
      >
        {chaos.enabled ? <ChaosIcon size={17} /> : <BotIcon size={17} />}
        {chaos.enabled ? <span>Caos · {chaosLabel.toLowerCase()}</span> : <span>Actores</span>}
        {on > 0 && (
          <span className="figures grid h-5 min-w-5 place-items-center rounded-md bg-current/15 px-1 text-[12px]">
            {on}
          </span>
        )}
      </button>

      {open && (
        <section
          role="dialog"
          aria-label="Actores simulados y modo caos"
          className="surface enter-pop absolute right-0 top-[calc(100%+12px)] z-40 w-[400px] overflow-hidden rounded-xl"
        >
          <header className="px-5 pb-3 pt-4">
            <h2 className="text-[17px] font-semibold tracking-[-0.01em]">Actores simulados</h2>
            <p className="mt-1 text-[13px] leading-snug text-muted">
              Usan los mismos servicios que una persona: el motor decide de verdad.
            </p>
          </header>

          <div className="divide-y divide-line border-y border-line">
            <SwitchRow
              title="Despachador automático"
              hint="Autoriza a los 10 s y confirma la carga a los 20 s, en cualquier central activa."
              checked={actors.autoDispatcher}
              disabled={busy}
              onChange={(value) => onChange({ autoDispatcher: value })}
            />
            <SwitchRow
              title="Flujo continuo de pedidos"
              hint="Un pedido simulado cada 3 min de reloj: 70 % urgencias, 30 % programados."
              checked={actors.orderFlow}
              disabled={busy}
              onChange={(value) => onChange({ orderFlow: value })}
            />
          </div>

          <div className="flex items-center gap-2 px-5 py-4">
            <span className="flex-1 text-[13px] text-muted">Generar ahora</span>
            <GenerateButton disabled={busy} onClick={() => onGenerate("emergency")}>
              <SurgeIcon size={16} />
              Urgencia
            </GenerateButton>
            <GenerateButton disabled={busy} onClick={() => onGenerate("scheduled")}>
              <PackageIcon size={16} />
              Programado
            </GenerateButton>
          </div>

          <div className="border-t border-line bg-ground/40">
            <SwitchRow
              title="Modo caos"
              hint="Sortea clima, fallas, choques y eventos del entorno con pesos realistas. Lo grave (dron perdido, choque grave, apagón) solo en alta."
              checked={chaos.enabled}
              disabled={busy}
              danger
              onChange={(value) => onChaos({ enabled: value })}
            />
            <div
              role="group"
              aria-label="Intensidad del caos"
              className="mx-5 mb-4 grid grid-cols-3 rounded-lg border border-line bg-ground p-0.5"
            >
              {INTENSITIES.map((item) => {
                const selected = chaos.intensity === item.value;
                return (
                  <button
                    key={item.value}
                    type="button"
                    aria-pressed={selected}
                    disabled={busy}
                    onClick={() => onChaos({ intensity: item.value })}
                    className={`press flex flex-col items-center rounded-md py-1.5 text-[13px] font-medium disabled:opacity-50 ${
                      selected
                        ? chaos.enabled
                          ? "bg-danger/14 text-danger"
                          : "bg-raised text-text shadow-[inset_0_0_0_1px_var(--line-strong)]"
                        : "text-muted hover:text-text"
                    }`}
                  >
                    {item.label}
                    <span className="figures text-[11px] font-normal opacity-75">{item.every}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <p className="border-t border-line px-5 py-3.5 text-[12.5px] leading-snug text-muted">
            El receptor simulado ingresa el código a tiempo en el 85 % de los pedidos generados; en el
            resto vencen los 5 min y el dron vuelve con el paquete.
          </p>
        </section>
      )}
    </div>
  );
}

function SwitchRow({
  title,
  hint,
  checked,
  disabled,
  danger = false,
  onChange,
}: {
  title: string;
  hint: string;
  checked: boolean;
  disabled: boolean;
  /** El caos se pinta en rojo cuando está encendido. */
  danger?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className="flex w-full items-start gap-4 px-5 py-3.5 text-left transition-colors hover:bg-hover disabled:opacity-55"
    >
      <span className="min-w-0 flex-1">
        <span className={`block text-[14px] font-medium ${checked && danger ? "text-danger" : "text-text"}`}>
          {title}
        </span>
        <span className="mt-0.5 block text-[12.5px] leading-snug text-muted">{hint}</span>
      </span>
      <span
        aria-hidden
        className={`relative mt-0.5 h-6 w-10 shrink-0 rounded-full border transition-colors duration-150 ${
          checked
            ? danger
              ? "border-danger bg-danger"
              : "border-accent bg-accent"
            : "border-line-strong bg-ground"
        }`}
      >
        <span
          className={`absolute top-[3px] size-4 rounded-full transition-[left,background-color] duration-150 ease-out ${
            checked ? "left-[19px] bg-on-accent" : "left-[3px] bg-muted"
          }`}
        />
      </span>
    </button>
  );
}

function GenerateButton({
  disabled,
  onClick,
  children,
}: {
  disabled: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="press flex h-9 items-center gap-1.5 rounded-lg border border-line-strong bg-raised px-3 text-[13px] font-medium text-text hover:bg-hover disabled:opacity-50"
    >
      {children}
    </button>
  );
}
