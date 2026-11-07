"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { DRONE_BODY, DRONE_ROTOR_R, DRONE_ROTORS, DRONE_WINGS } from "@/lib/drone-shape";
import { AlertIcon, HubIcon, LegendIcon, PowerOffIcon, StormIcon, WindIcon } from "./icons";
import { IconButton } from "./ui";

/** El dron del mapa, relleno, con el color de su estado. */
function DroneSwatch({ color }: { color: string }) {
  return (
    <svg viewBox="0 0 24 24" width={18} height={18} aria-hidden>
      <g fill={color} stroke="var(--ground)" strokeWidth={0.8}>
        <path d={DRONE_BODY} />
        {DRONE_WINGS.map((wing) => (
          <path key={wing} d={wing} />
        ))}
        {DRONE_ROTORS.map(([cx, cy]) => (
          <circle key={cx} cx={cx} cy={cy} r={DRONE_ROTOR_R} />
        ))}
      </g>
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
          className="surface absolute bottom-0 right-[calc(100%+8px)] w-[220px] rounded-xl p-4 [animation:enter-side_180ms_var(--ease-out)_both]"
        >
          <h3 className="mb-3 text-[13px] font-semibold">En el mapa</h3>
          <ul className="space-y-2.5 text-[13px] text-muted">
            <Item mark={<DroneSwatch color="var(--text)" />}>Dron de ida</Item>
            <Item mark={<DroneSwatch color="var(--warning)" />}>Dron de regreso</Item>
            <Item mark={<DroneSwatch color="var(--danger)" />}>Dron con alerta</Item>
            <Item mark={<HubIcon size={17} className="text-text" />}>Central</Item>
            <Item mark={<PowerOffIcon size={17} className="text-warning" />}>Sin energía</Item>
            <Item mark={<AlertIcon size={17} className="text-danger" />}>Espera rescate</Item>
            <Item
              mark={
                <span className="size-3.5 rounded-[3px] border border-magenta bg-[repeating-linear-gradient(135deg,rgb(224_90_214/0.35)_0_2px,transparent_2px_5px)]" />
              }
            >
              Zona restringida
            </Item>
            <Item mark={<span className="size-3.5 rounded-[3px] border border-dashed border-warning" />}>
              Zona temporal
            </Item>
            <Item mark={<WindIcon size={17} className="text-info" />}>Viento o lluvia</Item>
            <Item mark={<StormIcon size={17} className="text-danger" />}>Tormenta</Item>
          </ul>
        </div>
      )}
    </div>
  );
}
