import { DestinationKind } from '../common/enums/destination-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { DecisionTrace, DroneVerdict, HubTrace } from '../orders/order.entity';

/**
 * RF-39 y RF-11 para el público: por qué el sistema eligió esa central y ese
 * dron, en frases cortas y sin tecnicismos. Sale de la traza ya guardada; no
 * vuelve a calcular nada. No nombra el medicamento de una persona (RNF-05).
 */

/** Un bloque de la explicación: un título y hasta tres frases. */
export type TimelineSection = { title: string; lines: string[] };

/** Cuántas centrales y drones descartados se cuentan, como mucho. */
const MAX_OTHERS = 2;

type DecisionFacts = {
  missionType: MissionType;
  destinationKind: DestinationKind;
  medicationName: string;
};

/** La explicación de una autorización: por qué este nodo y por qué este dron. */
export function explainAssignment(
  trace: DecisionTrace | null,
  order: DecisionFacts,
): TimelineSection[] | null {
  if (!trace) {
    return null;
  }
  const chosenHub = trace.hubs.find((hub) =>
    hub.drones.some((drone) => drone.status === 'chosen'),
  );
  if (!chosenHub) {
    return explainNoFlight(trace, order);
  }
  return [
    hubSection(chosenHub, trace.hubs, order),
    droneSection(chosenHub, order),
  ];
}

/** Ningún dron salió: por qué, central por central. */
export function explainNoFlight(
  trace: DecisionTrace | null,
  order: DecisionFacts,
): TimelineSection[] | null {
  if (!trace) {
    return null;
  }
  const lines = trace.hubs
    .slice(0, MAX_OTHERS + 1)
    .map((hub) => hubProblem(hub, order))
    .filter((line): line is string => line != null);
  if (trace.reason) {
    lines.unshift(sentence(trace.reason));
  }
  return lines.length
    ? [{ title: 'Por qué no salió un dron', lines: lines.slice(0, 3) }]
    : null;
}

function hubSection(
  chosen: HubTrace,
  hubs: HubTrace[],
  order: DecisionFacts,
): TimelineSection {
  const lines = [`${chosen.name} tiene ${what(order)} y ${arrival(chosen)}.`];
  for (const other of hubs
    .filter((hub) => hub.hubId !== chosen.hubId)
    .slice(0, MAX_OTHERS)) {
    const problem = hubProblem(other, order);
    if (problem) {
      lines.push(problem);
    } else if (other.etaMin != null) {
      lines.push(
        `${other.name} también podía, pero tardaría ${minutes(other.etaMin)}.`,
      );
    }
  }
  return { title: 'Por qué esta central', lines };
}

function droneSection(hub: HubTrace, order: DecisionFacts): TimelineSection {
  const chosen = hub.drones.find((drone) => drone.status === 'chosen')!;
  const lines = [missionRule(order.missionType, chosen)];
  const discarded = hub.drones
    .filter((drone) => drone.status === 'discarded' && drone.reason)
    .slice(0, MAX_OTHERS);
  for (const drone of discarded) {
    lines.push(
      capitalize(
        `${droneName(drone)} no: ${lowerFirst(stripPeriod(drone.reason!))}.`,
      ),
    );
  }
  const eligible = hub.drones.filter((drone) => drone.status === 'eligible');
  if (eligible.length && discarded.length < MAX_OTHERS) {
    lines.push(
      eligible.length === 1
        ? capitalize(
            `${droneName(eligible[0])} también podía, pero ${slowerOrCostlier(order.missionType)}.`,
          )
        : `Otros ${eligible.length} drones podían, pero ${slowerOrCostlier(order.missionType)}.`,
    );
  }
  return { title: 'Por qué este dron', lines };
}

/** La regla de RF-11 dicha en una frase, con el dron que la ganó. */
function missionRule(missionType: MissionType, chosen: DroneVerdict): string {
  const name = droneName(chosen);
  const battery =
    chosen.batteryPercent != null
      ? ` Sale con ${Math.round(chosen.batteryPercent)} % de batería.`
      : '';
  if (chosen.preempts) {
    return `Es una urgencia: ${name} deja un pedido programado y sale primero.${battery}`;
  }
  return missionType === MissionType.EMERGENCY
    ? `Es una urgencia: gana el que llega antes, y ese es ${name}.${battery}`
    : `Es programado: gana el que gasta menos batería, y ese es ${name}.${battery}`;
}

function slowerOrCostlier(missionType: MissionType): string {
  return missionType === MissionType.EMERGENCY
    ? 'llegaba después'
    : 'gastaba más batería';
}

/** Por qué una central no sirvió, o `null` si sí podía. */
function hubProblem(hub: HubTrace, order: DecisionFacts): string | null {
  if (hub.note && !hub.lot) {
    return `${hub.name}: ${lowerFirst(stripPeriod(hub.note))}.`;
  }
  if (!hub.lot) {
    return `${hub.name} no tiene ${what(order)}.`;
  }
  if (hub.corridorKm == null) {
    return `${hub.name} no tiene una ruta libre de zonas restringidas.`;
  }
  if (!hub.inRange) {
    return `${hub.name} queda lejos: sus drones no alcanzan a ir y volver.`;
  }
  const usable = hub.drones.some(
    (drone) => drone.status === 'chosen' || drone.status === 'eligible',
  );
  if (!usable && hub.drones.length) {
    const first = hub.drones.find((drone) => drone.reason);
    return first?.reason
      ? `${hub.name} no tiene un dron listo: ${lowerFirst(stripPeriod(first.reason))}.`
      : `${hub.name} no tiene un dron listo.`;
  }
  return null;
}

/** El insumo, sin nombrar el medicamento de una persona (RNF-05). */
function what(order: DecisionFacts): string {
  return order.destinationKind === DestinationKind.HUB
    ? `${order.medicationName} con lote vigente`
    : 'el medicamento con lote vigente';
}

function arrival(hub: HubTrace): string {
  if (hub.etaMin == null || hub.corridorKm == null) {
    return 'un dron que llega';
  }
  const km = hub.corridorKm.toLocaleString('es-CO', {
    maximumFractionDigits: 1,
  });
  return `está a ${km} km: llega en ${minutes(hub.etaMin)}`;
}

function minutes(value: number): string {
  const rounded = Math.max(1, Math.round(value));
  return rounded === 1 ? '1 min' : `${rounded} min`;
}

function droneName(drone: DroneVerdict): string {
  return drone.typeName
    ? `el ${drone.typeName} ${drone.identifier}`
    : drone.identifier;
}

function sentence(text: string): string {
  const trimmed = text.trim();
  return /[.!?]$/.test(trimmed) ? trimmed : `${trimmed}.`;
}

function stripPeriod(text: string): string {
  return text.trim().replace(/\.$/, '');
}

function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function lowerFirst(text: string): string {
  return text.charAt(0).toLowerCase() + text.slice(1);
}
