import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import {
  DecisionOutcome,
  DecisionTrace,
  DispatchOffer,
  DroneVerdict,
  HubTrace,
} from '../orders/order.entity';
import { PlannedCorridor } from '../routing/routing.rules';
import { missionBatteryPercent } from '../simulation/flight-energy.rules';
import { ChosenDrone, DiscardedDrone } from './decision.rules';

/**
 * Explica una decisión del motor con lo que ya calculó: qué centrales miró,
 * si tenían lote y corredor, cuánta batería pedía el vuelo y qué pasó con
 * cada dron. Se guarda en el pedido; no vuelve a calcular nada.
 */

export const HUB_SUSPENDED_NOTE = 'La central está suspendida.';
export const NO_LOT_NOTE = 'No tiene un lote vigente con la cantidad.';
export const NO_CORRIDOR_NOTE = 'No hay un corredor libre de geovallas.';
export const ONLY_STOCK_NOTE =
  'Solo se revisó el stock: ya intentó o es la central que pidió.';

/** Lo que `HubEvaluationService.evaluate` devuelve y la traza necesita. */
export type EvaluationView = {
  lot: object | null;
  drones: Array<{ id: string; identifier: string; droneModelId: string }>;
  modelsById: Map<string, { maxRangeKm: number }>;
  corridor: PlannedCorridor | null;
  choice: { chosen: ChosenDrone | null; discarded: DiscardedDrone[] };
  etaMs: number | null;
  inRange: boolean;
};

type HubRef = { id: string; name: string };

export function traceEvaluatedHub(
  hub: HubRef,
  evaluation: EvaluationView,
): HubTrace {
  const model = evaluation.modelsById.get(
    evaluation.drones[0]?.droneModelId ?? '',
  );
  const corridorKm = evaluation.corridor?.distanceKm ?? null;
  return {
    hubId: hub.id,
    name: hub.name,
    lot: evaluation.lot != null,
    corridorKm,
    etaMin:
      evaluation.etaMs != null && Number.isFinite(evaluation.etaMs)
        ? roundTo(evaluation.etaMs / 60_000, 1)
        : null,
    batteryNeededPercent:
      corridorKm != null && model
        ? roundTo(missionBatteryPercent(corridorKm, model.maxRangeKm), 1)
        : null,
    inRange: evaluation.inRange,
    note: noteFor(evaluation),
    drones: evaluation.lot ? droneVerdicts(evaluation) : [],
  };
}

/** Una central que no se evaluó con drones (suspendida o solo por stock). */
export function traceSkippedHub(
  hub: HubRef,
  lot: boolean,
  note: string,
): HubTrace {
  return {
    hubId: hub.id,
    name: hub.name,
    lot,
    corridorKm: null,
    etaMin: null,
    batteryNeededPercent: null,
    inRange: false,
    note,
    drones: [],
  };
}

export function buildDecisionTrace(
  order: {
    status: OrderStatus;
    fallbackKind: FallbackKind | null;
    fallbackReason: string | null;
    statusReason: string | null;
  },
  hubs: HubTrace[],
  now: Date,
): DecisionTrace {
  const outcome = outcomeOf(order);
  return {
    at: now.toISOString(),
    outcome,
    reason:
      outcome === 'assigned'
        ? null
        : (order.fallbackReason ?? order.statusReason ?? null),
    hubs,
  };
}

export function outcomeOf(order: {
  status: OrderStatus;
  fallbackKind: FallbackKind | null;
}): DecisionOutcome {
  if (order.status === OrderStatus.PENDING_LOAD) return 'assigned';
  if (order.status === OrderStatus.REJECTED) return 'rejected';
  if (order.status === OrderStatus.EXPIRED) return 'expired';
  if (order.fallbackKind === FallbackKind.RETRY) return 'retry';
  if (order.fallbackKind === FallbackKind.HUB) return 'reassigned';
  return 'conventional';
}

/**
 * `GET /orders/:id/decision`: la traza más la escalera de ofertas de una
 * urgencia civil (RU-10), con minutos en vez de milisegundos.
 */
export function presentDecision(order: {
  id: string;
  decisionTrace: DecisionTrace | null;
  dispatchOffers: DispatchOffer[] | null;
}) {
  return {
    orderId: order.id,
    trace: order.decisionTrace,
    offers:
      order.dispatchOffers?.map((offer) => ({
        hubId: offer.hubId,
        name: offer.name,
        etaMin: roundTo(offer.etaMs / 60_000, 1),
        ready: offer.ready,
        offeredAt: offer.offeredAt,
        declinedAt: offer.declinedAt,
        declineReason: offer.declineReason,
      })) ?? null,
  };
}

function noteFor(evaluation: EvaluationView): string | null {
  if (!evaluation.lot) return NO_LOT_NOTE;
  if (!evaluation.corridor) return NO_CORRIDOR_NOTE;
  return null;
}

function droneVerdicts(evaluation: EvaluationView): DroneVerdict[] {
  const { chosen, discarded } = evaluation.choice;
  const reasons = new Map(discarded.map((row) => [row.droneId, row.reason]));
  return evaluation.drones.map((drone) => {
    if (chosen?.droneId === drone.id) {
      return {
        identifier: drone.identifier,
        status: 'chosen',
        reason: null,
        preempts: chosen.preemptsOrderId != null,
      };
    }
    const reason = reasons.get(drone.id);
    return {
      identifier: drone.identifier,
      status: reason ? 'discarded' : 'eligible',
      reason: reason ?? null,
      preempts: false,
    };
  });
}

function roundTo(value: number, digits: number): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}
