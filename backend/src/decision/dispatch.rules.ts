import { ForbiddenException } from '@nestjs/common';
import { DispatchOffer } from '../orders/order.entity';

/**
 * RU-10 y RF-18: una urgencia civil se ofrece primero a la central que llega
 * antes. Si no la autoriza a tiempo, la oferta se amplía a la siguiente sin
 * quitársela a la primera: gana la que autorice primero entre las ofrecidas.
 *
 * La ventaja de cada central es lo que ahorra frente a la siguiente, entre
 * 1 y 3 minutos: pasado ese tiempo, esperarla ya no es más rápido.
 */
export const MIN_HEAD_START_MS = 60_000;
export const MAX_HEAD_START_MS = 180_000;

export const NOT_OFFERED_TO_HUB =
  'Esta urgencia todavía no está en la cola de tu central.';

export const ALREADY_DECLINED = 'Tu central ya declinó esta urgencia.';

export const ONLY_OPEN_EMERGENCY_IS_DECLINED =
  'Solo se declina una urgencia recibida que todavía no tiene central.';

export const NO_HUB_WITHIN_RANGE =
  'Ninguna central con el insumo tiene un dron que alcance este destino. Toca un traslado convencional desde una central con el insumo.';

export const EVERY_HUB_DECLINED =
  'Ninguna central pudo atender la urgencia. Toca un traslado convencional desde una central con el insumo.';

/** Una central que puede atender: tiene el lote y un corredor que la batería alcanza. */
export type DispatchCandidate = {
  hubId: string;
  name: string;
  etaMs: number;
  /** Tiene un dron elegible ahora mismo. */
  ready: boolean;
};

/**
 * Orden de la oferta: primero las que tienen dron listo, y dentro de cada
 * grupo la que llega antes; empate por nombre.
 */
export function rankDispatchCandidates(
  candidates: DispatchCandidate[],
): DispatchOffer[] {
  return [...candidates]
    .sort(
      (left, right) =>
        Number(right.ready) - Number(left.ready) ||
        left.etaMs - right.etaMs ||
        left.name.localeCompare(right.name),
    )
    .map((candidate) => ({
      ...candidate,
      offeredAt: null,
      declinedAt: null,
      declineReason: null,
    }));
}

/** Lo que ahorra `current` frente a `next`, entre 1 y 3 min. Sin siguiente, `null`. */
export function headStartMs(
  current: Pick<DispatchCandidate, 'etaMs'>,
  next: Pick<DispatchCandidate, 'etaMs'> | undefined,
): number | null {
  if (!next) {
    return null;
  }
  return Math.min(
    MAX_HEAD_START_MS,
    Math.max(MIN_HEAD_START_MS, next.etaMs - current.etaMs),
  );
}

export type OfferStep = {
  offers: DispatchOffer[];
  /** Central a la que se acaba de ofrecer, para avisarle. */
  openedHubId: string | null;
  nextEscalationAt: Date | null;
};

/**
 * Ofrece la urgencia a la siguiente central de la lista y calcula cuándo se
 * amplía otra vez. Sin centrales pendientes, no abre nada ni programa más.
 */
export function openNextOffer(offers: DispatchOffer[], now: Date): OfferStep {
  const index = offers.findIndex((offer) => offer.offeredAt == null);
  if (index === -1) {
    return { offers, openedHubId: null, nextEscalationAt: null };
  }
  const next = offers.map((offer, at) =>
    at === index ? { ...offer, offeredAt: now.toISOString() } : offer,
  );
  const wait = headStartMs(next[index], next[index + 1]);
  return {
    offers: next,
    openedHubId: next[index].hubId,
    nextEscalationAt: wait == null ? null : new Date(now.getTime() + wait),
  };
}

/** La central ya la ve en su cola y no la declinó. */
export function isOfferedTo(offers: DispatchOffer[], hubId: string): boolean {
  return offers.some(
    (offer) =>
      offer.hubId === hubId &&
      offer.offeredAt != null &&
      offer.declinedAt == null,
  );
}

export function assertOfferedTo(offers: DispatchOffer[], hubId: string): void {
  if (!isOfferedTo(offers, hubId)) {
    throw new ForbiddenException(NOT_OFFERED_TO_HUB);
  }
}

/**
 * La central dice que no puede (sin dron, sin personal, sin lote). Se ofrece
 * en ese instante a la siguiente, sin esperar la ventaja.
 */
export function declineOffer(
  offers: DispatchOffer[],
  hubId: string,
  reason: string | null,
  now: Date,
): OfferStep {
  const own = offers.find((offer) => offer.hubId === hubId);
  if (own?.declinedAt != null) {
    throw new ForbiddenException(ALREADY_DECLINED);
  }
  assertOfferedTo(offers, hubId);
  const declined = offers.map((offer) =>
    offer.hubId === hubId
      ? { ...offer, declinedAt: now.toISOString(), declineReason: reason }
      : offer,
  );
  return openNextOffer(declined, now);
}

/**
 * RF-36: la central se quedó sin energía. Sale de la lista como si hubiera
 * declinado, aunque todavía no le tocara: así la escalera ya no se la
 * ofrece. Si era la que la tenía abierta, se abre la siguiente ya.
 * `null` si la central no estaba en la lista o ya la había declinado.
 */
export function withdrawHub(
  offers: DispatchOffer[],
  hubId: string,
  reason: string,
  now: Date,
): { offers: DispatchOffer[]; step: OfferStep | null } | null {
  const own = offers.find((offer) => offer.hubId === hubId);
  if (!own || own.declinedAt != null) {
    return null;
  }
  const wasOpen = own.offeredAt != null;
  const stamp = now.toISOString();
  const withdrawn = offers.map((offer) =>
    offer.hubId === hubId
      ? {
          ...offer,
          offeredAt: offer.offeredAt ?? stamp,
          declinedAt: stamp,
          declineReason: reason,
        }
      : offer,
  );
  return {
    offers: withdrawn,
    step: wasOpen ? openNextOffer(withdrawn, now) : null,
  };
}

/** Todas las centrales de la lista la vieron y la declinaron. */
export function everyHubDeclined(offers: DispatchOffer[]): boolean {
  return offers.every((offer) => offer.declinedAt != null);
}
