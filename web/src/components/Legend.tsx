import type { ReactNode } from "react";
import { BrandMark } from "./BrandMark";
import { AlertIcon, HubIcon, PowerOffIcon, StormIcon, WindIcon, ZoneIcon } from "./icons";

function Item({ mark, children }: { mark: ReactNode; children: ReactNode }) {
  return (
    <li className="flex items-center gap-2.5">
      <span className="grid w-5 place-items-center">{mark}</span>
      {children}
    </li>
  );
}

/** Un dron de la marca en su disco, con el borde del color de la misión. */
function DroneDot({ ring }: { ring: string }) {
  return (
    <span className={`grid size-5 place-items-center rounded-full border-[1.5px] bg-ink ${ring}`}>
      <BrandMark size={14} spin={false} />
    </span>
  );
}

/**
 * Qué significa cada cosa del mapa. A la derecha, sobre los botones del mapa;
 * con un panel abierto se corre a su lado. Solo en pantallas medianas o más.
 */
export function Legend({ panelOpen }: { panelOpen: boolean }) {
  return (
    <ul
      aria-label="Leyenda del mapa"
      className={`glass pointer-events-none absolute bottom-[290px] z-10 hidden w-[196px] flex-col gap-2 rounded-[22px] px-4 py-3.5 text-[13px] text-muted transition-[right] duration-300 lg:flex ${panelOpen ? "right-[432px]" : "right-4"}`}
    >
      <li className="eyebrow mb-0.5 !text-[10px]">En el mapa</li>
      <Item mark={<HubIcon size={16} className="text-accent" />}>Central</Item>
      <Item mark={<PowerOffIcon size={16} className="text-warning" />}>Sin energía</Item>
      <Item mark={<DroneDot ring="border-accent-from" />}>Ida</Item>
      <Item mark={<DroneDot ring="border-warning" />}>Regreso</Item>
      <Item mark={<DroneDot ring="border-danger" />}>Con alerta</Item>
      <Item mark={<AlertIcon size={16} className="text-danger" />}>Espera rescate</Item>
      <Item mark={<span className="size-3.5 rounded-[4px] border border-dashed border-danger bg-danger/15" />}>
        Zona restringida
      </Item>
      <Item mark={<ZoneIcon size={16} className="text-warning" />}>Zona temporal</Item>
      <Item mark={<WindIcon size={16} className="text-info" />}>Viento o lluvia</Item>
      <Item mark={<StormIcon size={16} className="text-danger" />}>Tormenta</Item>
    </ul>
  );
}
