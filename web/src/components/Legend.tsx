import type { ReactNode } from "react";
import { DroneIcon, HubIcon } from "./icons";

function Item({ mark, children }: { mark: ReactNode; children: ReactNode }) {
  return (
    <li className="flex items-center gap-2">
      {mark}
      {children}
    </li>
  );
}

/** Qué significa cada color del mapa. Solo en pantallas medianas o más. */
export function Legend() {
  return (
    <ul
      aria-label="Leyenda del mapa"
      className="glass pointer-events-none absolute bottom-4 left-4 z-10 hidden h-14 items-center gap-5 rounded-2xl px-4 text-xs text-muted md:flex"
    >
      <Item mark={<HubIcon size={16} className="text-accent" />}>Central</Item>
      <Item mark={<DroneIcon size={16} className="text-accent-from" />}>Ida</Item>
      <Item mark={<DroneIcon size={16} className="text-warning" />}>Regreso</Item>
      <Item mark={<DroneIcon size={16} className="text-danger" />}>Con alerta</Item>
      <Item mark={<span className="size-3.5 rounded-[4px] border border-dashed border-danger bg-danger/15" />}>
        Zona restringida
      </Item>
    </ul>
  );
}
