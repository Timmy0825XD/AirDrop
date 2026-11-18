"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import {
  AlertIcon,
  FogIcon,
  HubIcon,
  LegendIcon,
  PowerOffIcon,
  StormIcon,
  WindIcon,
} from "./icons";
import { IconButton } from "./ui";

/** El dron del mapa (el de la app) con el color de su estado. */
function DroneSwatch({ color }: { color: string }) {
  return (
    <svg viewBox="0 0 34 34" width={20} height={20} aria-hidden>
      <g fill="none" stroke={color} strokeWidth={2.4} strokeLinecap="round">
        <path d="M11 11l12 12M23 11L11 23" />
        <circle cx={9} cy={9} r={5.5} />
        <circle cx={25} cy={9} r={5.5} />
        <circle cx={9} cy={25} r={5.5} />
        <circle cx={25} cy={25} r={5.5} />
      </g>
      <rect x={12.5} y={12.5} width={9} height={9} rx={3} fill="var(--accent)" stroke={color} strokeWidth={2} />
    </svg>
  );
}

function Item({ mark, children }: { mark: ReactNode; children: ReactNode }) {
  return (
    <li className="flex items-center gap-3">
      <span className="grid w-5 place-items-center">{mark}</span>
      {children}
    </li>
  );
}

/**
 * Qué significa cada cosa del mapa. Plegada en un botón junto a los mandos
 * del mapa: en la TV se abre una vez y se cierra.
 */
export function Legend() {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);

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
    <div ref={box} className="relative">
      <IconButton
        label={open ? "Cerrar la leyenda" : "Leyenda del mapa"}
        onClick={() => setOpen((value) => !value)}
        pressed={open}
        active={open}
      >
        <LegendIcon size={18} />
      </IconButton>
      {open && (
        <div
          role="dialog"
          aria-label="Leyenda del mapa"
          className="surface absolute bottom-0 right-[calc(100%+8px)] w-[270px] rounded-xl p-4 [animation:enter-side_180ms_var(--ease-out)_both]"
        >
          <h3 className="mb-3 text-[13px] font-semibold">En el mapa</h3>
          <ul className="space-y-2.5 text-[13px] text-muted">
            <Item mark={<DroneSwatch color="var(--text)" />}>Dron de ida</Item>
            <Item mark={<DroneSwatch color="var(--warning)" />}>Dron de regreso</Item>
            <Item mark={<DroneSwatch color="var(--danger)" />}>Dron con alerta</Item>
            <Item mark={<HubIcon size={17} className="text-text" />}>Central (tiene drones)</Item>
            <Item
              mark={
                <span className="grid h-5 w-7 place-items-center rounded-full border-[1.5px] border-accent text-[10px] font-bold text-text">
                  6
                </span>
              }
            >
              «6 centrales»: varias juntas; tócalo para acercar
            </Item>
            <Item mark={<PowerOffIcon size={17} className="text-warning" />}>Sin energía</Item>
            <Item mark={<AlertIcon size={17} className="text-danger" />}>Espera rescate</Item>
            <Item
              mark={
                <span className="size-3.5 rounded-[3px] border border-magenta bg-[repeating-linear-gradient(135deg,color-mix(in_srgb,var(--magenta)_35%,transparent)_0_2px,transparent_2px_5px)]" />
              }
            >
              Zona restringida
            </Item>
            <Item mark={<span className="size-3.5 rounded-[3px] border border-dashed border-warning" />}>
              Zona temporal
            </Item>
            <Item mark={<span className="size-3.5 rounded-full border border-danger bg-danger/15" />}>
              No se vuela: aeropuerto, CAI, batallón, cárcel, planta, pista
            </Item>
            <Item mark={<WindIcon size={17} className="text-info" />}>Viento o lluvia</Item>
            <Item mark={<StormIcon size={17} className="text-danger" />}>Tormenta</Item>
            <Item mark={<FogIcon size={17} className="text-text" />}>Niebla (no se vuela)</Item>
            <Item mark={<span className="size-3 rounded-full bg-magenta" />}>
              Dron no identificado
            </Item>
          </ul>
        </div>
      )}
    </div>
  );
}
