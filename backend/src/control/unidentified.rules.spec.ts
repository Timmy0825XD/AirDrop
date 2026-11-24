import {
  NEAR_CORRIDOR_KM,
  contactPosition,
  crossingThrough,
  distanceToPathKm,
  nearCorridor,
  randomContactMinutes,
} from './unidentified.rules';
import { haversineKm } from '../routing/routing.rules';

const contact = {
  from: { latitude: 10.4, longitude: -73.3 },
  to: { latitude: 10.4, longitude: -73.1 },
  startedAtMs: 0,
  endsAtMs: 10 * 60_000,
};

describe('Dron no identificado (RF-36)', () => {
  it('avanza en línea recta y se queda al final', () => {
    expect(contactPosition(contact, 5 * 60_000)).toEqual({
      latitude: 10.4,
      longitude: -73.2,
    });
    expect(contactPosition(contact, 99 * 60_000)).toEqual(contact.to);
  });

  it('avisa a menos de 1 km de un corredor activo, no más lejos', () => {
    const corridor = {
      identifier: 'AD-SUR-01',
      coordinates: [
        [-73.2, 10.3],
        [-73.2, 10.5],
      ],
    };
    expect(
      distanceToPathKm(
        { latitude: 10.4, longitude: -73.2 },
        corridor.coordinates,
      ),
    ).toBeCloseTo(0, 5);
    expect(
      nearCorridor({ latitude: 10.4, longitude: -73.195 }, [corridor]),
    ).toBe(corridor);
    expect(
      nearCorridor({ latitude: 10.4, longitude: -73.18 }, [corridor]),
    ).toBeNull();
    expect(NEAR_CORRIDOR_KM).toBe(1);
  });

  it('el cruce pasa por el punto pedido y dura de 5 a 30 minutos', () => {
    const through = { latitude: 10.4, longitude: -73.25 };
    const { from, to } = crossingThrough(through, () => 0.25);
    const middle = {
      latitude: (from.latitude + to.latitude) / 2,
      longitude: (from.longitude + to.longitude) / 2,
    };
    expect(haversineKm(middle, through)).toBeLessThan(0.01);
    expect(randomContactMinutes(() => 0)).toBe(5);
    expect(randomContactMinutes(() => 0.999)).toBe(30);
  });
});
