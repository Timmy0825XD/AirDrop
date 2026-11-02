import { ForbiddenException } from '@nestjs/common';
import {
  ALREADY_DECLINED,
  DispatchCandidate,
  MAX_HEAD_START_MS,
  MIN_HEAD_START_MS,
  NOT_OFFERED_TO_HUB,
  declineOffer,
  everyHubDeclined,
  headStartMs,
  isOfferedTo,
  openNextOffer,
  rankDispatchCandidates,
} from './dispatch.rules';

const MIN = 60_000;
const t0 = new Date('2026-11-02T15:00:00.000Z');
const at = (ms: number) => new Date(t0.getTime() + ms);

const hub = (
  hubId: string,
  etaMin: number,
  ready = true,
): DispatchCandidate => ({
  hubId,
  name: `Central ${hubId}`,
  etaMs: etaMin * MIN,
  ready,
});

describe('rankDispatchCandidates', () => {
  it('pone primero las centrales con dron listo y, dentro, la que llega antes', () => {
    const ranked = rankDispatchCandidates([
      hub('lejana', 14),
      hub('cercana-sin-dron', 4, false),
      hub('cercana', 6),
      hub('media', 7.5),
    ]);
    expect(ranked.map((offer) => offer.hubId)).toEqual([
      'cercana',
      'media',
      'lejana',
      'cercana-sin-dron',
    ]);
    expect(ranked.every((offer) => offer.offeredAt === null)).toBe(true);
  });
});

describe('headStartMs', () => {
  it('da de ventaja lo que la central ahorra frente a la siguiente', () => {
    expect(headStartMs(hub('a', 6), hub('b', 7.5))).toBe(1.5 * MIN);
  });

  it('nunca menos de 1 min ni más de 3 min', () => {
    expect(headStartMs(hub('a', 6), hub('b', 6.2))).toBe(MIN_HEAD_START_MS);
    expect(headStartMs(hub('a', 4), hub('b', 20))).toBe(MAX_HEAD_START_MS);
  });

  it('sin siguiente central no hay a quién ampliar', () => {
    expect(headStartMs(hub('a', 6), undefined)).toBeNull();
  });
});

describe('openNextOffer', () => {
  const ranked = rankDispatchCandidates([
    hub('A', 6),
    hub('B', 7.5),
    hub('C', 14),
  ]);

  it('sigue la línea de tiempo A → B (1,5 min) → C (4,5 min)', () => {
    const first = openNextOffer(ranked, t0);
    expect(first.openedHubId).toBe('A');
    expect(first.nextEscalationAt).toEqual(at(1.5 * MIN));
    expect(isOfferedTo(first.offers, 'A')).toBe(true);
    expect(isOfferedTo(first.offers, 'B')).toBe(false);

    const second = openNextOffer(first.offers, at(1.5 * MIN));
    expect(second.openedHubId).toBe('B');
    expect(second.nextEscalationAt).toEqual(at(4.5 * MIN));
    // Ampliar no le quita la urgencia a la primera.
    expect(isOfferedTo(second.offers, 'A')).toBe(true);

    const third = openNextOffer(second.offers, at(4.5 * MIN));
    expect(third.openedHubId).toBe('C');
    expect(third.nextEscalationAt).toBeNull();

    const none = openNextOffer(third.offers, at(6 * MIN));
    expect(none.openedHubId).toBeNull();
    expect(none.offers).toBe(third.offers);
  });
});

describe('declineOffer', () => {
  const opened = openNextOffer(
    rankDispatchCandidates([hub('A', 6), hub('B', 7.5), hub('C', 14)]),
    t0,
  ).offers;

  it('al declinar, la siguiente central la ve en ese instante', () => {
    const step = declineOffer(opened, 'A', 'Sin dron', at(20_000));
    expect(step.openedHubId).toBe('B');
    expect(isOfferedTo(step.offers, 'A')).toBe(false);
    expect(isOfferedTo(step.offers, 'B')).toBe(true);
    expect(step.offers[0].declineReason).toBe('Sin dron');
    expect(step.nextEscalationAt).toEqual(at(20_000 + 3 * MIN));
  });

  it('una central a la que no se le ofreció no puede declinar', () => {
    expect(() => declineOffer(opened, 'C', null, t0)).toThrow(
      new ForbiddenException(NOT_OFFERED_TO_HUB),
    );
  });

  it('no se declina dos veces', () => {
    const step = declineOffer(opened, 'A', null, t0);
    expect(() => declineOffer(step.offers, 'A', null, t0)).toThrow(
      new ForbiddenException(ALREADY_DECLINED),
    );
  });

  it('cuando todas declinan no queda a quién ofrecer', () => {
    let offers = opened;
    for (const id of ['A', 'B', 'C']) {
      offers = declineOffer(offers, id, null, t0).offers;
    }
    expect(everyHubDeclined(offers)).toBe(true);
  });
});
