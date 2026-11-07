"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import type { ActorsState, GeneratedKind } from "@/lib/types";
import { BotIcon, CloseIcon, PackageIcon, SurgeIcon } from "./icons";
import { GlassButton, IconTile } from "./ui";

type Props = {
  actors: ActorsState;
  busy: boolean;
  onChange: (change: Partial<ActorsState>) => void;
  onGenerate: (kind: GeneratedKind) => void;
};

/**
 * RF-37, CU-39: los actores simulados. Un botón en la barra abre la tarjeta
 * con los dos interruptores (despachador automático y flujo continuo) y el
 * generador a pedido. El pico de urgencias va en la barra de eventos, porque
 * se elige sobre el mapa.
 */
export function ActorsMenu({ actors, busy, onChange, onGenerate }: Props) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const on = Number(actors.autoDispatcher) + Number(actors.orderFlow);

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
        title="Actores simulados"
        className={`flex h-10 items-center gap-2 rounded-[13px] border px-3 text-sm font-semibold transition active:scale-95 focus-visible:outline-2 focus-visible:outline-accent ${
          on > 0
            ? "border-accent/45 bg-accent/12 text-accent"
            : "border-glass-border bg-glass text-text hover:text-accent"
        }`}
      >
        <BotIcon size={17} />
        <span className="hidden 2xl:inline">Actores</span>
        {on > 0 && (
          <span className="grid size-5 place-items-center rounded-full bg-accent text-[11px] font-bold text-on-accent tabular-nums">
            {on}
          </span>
        )}
      </button>

      {open && (
        <section
          role="dialog"
          aria-label="Actores simulados"
          className="glass rise-in absolute right-0 top-[calc(100%+18px)] z-40 w-[400px] rounded-[28px] p-5"
        >
          <header className="flex items-start gap-3.5">
            <IconTile tone="info">
              <BotIcon size={24} />
            </IconTile>
            <div className="min-w-0 flex-1">
              <h2 className="text-[22px] font-semibold leading-[1.08] tracking-[-0.03em]">
                Actores simulados
              </h2>
              <p className="mt-1 text-[13px] leading-snug text-muted">
                Usan los mismos servicios que una persona: el motor decide de verdad.
              </p>
            </div>
            <GlassButton label="Cerrar" onClick={() => setOpen(false)} className="!size-10 !rounded-[13px]">
              <CloseIcon size={16} />
            </GlassButton>
          </header>

          <div className="mt-4 space-y-2">
            <SwitchRow
              title="Despachador automático"
              hint="Autoriza a los 10 s y confirma la carga a los 20 s, en cualquier central activa. Pedidos reales y generados."
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

          <div className="mt-4">
            <span className="eyebrow">Generar ahora</span>
            <div className="mt-2 grid grid-cols-2 gap-2">
              <GenerateButton disabled={busy} onClick={() => onGenerate("emergency")}>
                <SurgeIcon size={18} />
                Urgencia
              </GenerateButton>
              <GenerateButton disabled={busy} onClick={() => onGenerate("scheduled")}>
                <PackageIcon size={18} />
                Programado
              </GenerateButton>
            </div>
          </div>

          <p className="mt-4 rounded-2xl border border-glass-border bg-white/4 px-4 py-3 text-[13px] leading-snug text-muted">
            El receptor simulado ingresa el código a tiempo en el 85 % de los pedidos generados; en el
            resto vencen los 5 min y el dron vuelve con el paquete. El pico de urgencias se lanza
            desde la barra de abajo.
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
  onChange,
}: {
  title: string;
  hint: string;
  checked: boolean;
  disabled: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`flex w-full items-center gap-3 rounded-[20px] border px-4 py-3 text-left transition active:scale-[0.99] disabled:opacity-55 focus-visible:outline-2 focus-visible:outline-accent ${
        checked ? "border-accent/40 bg-accent/10" : "border-glass-border bg-white/4 hover:bg-white/8"
      }`}
    >
      <span className="min-w-0 flex-1">
        <span className="block text-[16px] font-semibold">{title}</span>
        <span className="mt-0.5 block text-[13px] leading-snug text-muted">{hint}</span>
      </span>
      <span
        aria-hidden
        className={`relative h-7 w-12 shrink-0 rounded-full transition ${checked ? "bg-accent-gradient" : "bg-white/15"}`}
      >
        <span
          className={`absolute top-1 size-5 rounded-full bg-white shadow transition-all ${checked ? "left-6" : "left-1"}`}
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
      className="flex h-12 items-center justify-center gap-2 rounded-[16px] border border-glass-border bg-glass text-[15px] font-semibold text-text transition hover:border-accent/40 hover:text-accent active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent"
    >
      {children}
    </button>
  );
}
