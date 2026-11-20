import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { DRONE_TYPES } from '../fleet/drone-types';
import {
  DroneCandidate,
  NEEDS_COLD_COMPARTMENT,
  PAYLOAD_TOO_HEAVY,
  chooseDrone,
  payloadKgOf,
} from './decision.rules';

/**
 * RF-11 y RF-49 con los tres tipos reales y los ejemplos de
 * `context/operacion/flota.md`.
 */
const [colibri, garza, condor] = DRONE_TYPES;

function candidate(
  spec: (typeof DRONE_TYPES)[number],
  id: string,
  coldCompartment = false,
): DroneCandidate {
  return {
    id,
    identifier: id,
    status: DroneStatus.AVAILABLE,
    maxPayloadKg: spec.maxPayloadKg,
    maxRangeKm: spec.maxRangeKm,
    coldCompartment,
    cruiseKmh: spec.maxSpeedKmh,
    batteryWh: spec.batteryWh,
    held: null,
    batteryPercent: 100,
    lastFlightEndedAt: null,
  };
}

const fleet = (km: number, cold = false) => [
  { drone: candidate(colibri, 'colibri', cold), distanceKm: km },
  { drone: candidate(garza, 'garza', cold), distanceKm: km },
  { drone: candidate(condor, 'condor', cold), distanceKm: km },
];

describe('Selección por tipo de misión (RF-11, flota.md)', () => {
  it('antiveneno a Patillal (urgencia, 0,3 kg, frío): gana el Colibrí, que llega antes', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 2,
      payloadKg: 0.3,
      requiresCold: true,
      weatherFlyable: true,
      candidates: fleet(11.1, true),
    });
    expect(result.chosen?.identifier).toBe('colibri');
  });

  it('reabastecer el hospital de La Paz (programado, 12 kg): solo el Cóndor la lleva', () => {
    const result = chooseDrone({
      missionType: MissionType.SCHEDULED,
      quantity: 400,
      payloadKg: 12,
      weatherFlyable: true,
      candidates: fleet(4.9),
    });
    expect(result.chosen?.identifier).toBe('condor');
    expect(
      result.discarded.map((entry) => [entry.identifier, entry.reason]),
    ).toEqual([
      ['colibri', PAYLOAD_TOO_HEAVY],
      ['garza', PAYLOAD_TOO_HEAVY],
    ]);
  });

  it('Villa Germania (34 km): solo el Colibrí tiene batería para ir y volver', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      payloadKg: 0.5,
      weatherFlyable: true,
      candidates: fleet(34.1),
    });
    expect(result.chosen?.identifier).toBe('colibri');
    expect(result.discarded.map((entry) => entry.identifier)).toEqual([
      'garza',
      'condor',
    ]);
  });

  it('un programado liviano y cercano lo toma el que gasta menos energía', () => {
    const result = chooseDrone({
      missionType: MissionType.SCHEDULED,
      quantity: 10,
      payloadKg: 1,
      weatherFlyable: true,
      candidates: [
        { drone: candidate(garza, 'garza'), distanceKm: 5 },
        { drone: candidate(condor, 'condor'), distanceKm: 5 },
      ],
    });
    // Garza: 2×(8 + 5,6) + 20 = 47 % de 1.500 Wh ≈ 705 Wh.
    // Cóndor: 2×(8 + 16,7) + 20 = 69 % de 2.000 Wh ≈ 1.387 Wh.
    expect(result.chosen?.identifier).toBe('garza');
  });

  it('una carga con frío no va en un dron sin compartimento', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      payloadKg: 0.2,
      requiresCold: true,
      weatherFlyable: true,
      candidates: [{ drone: candidate(colibri, 'colibri'), distanceKm: 5 }],
    });
    expect(result.chosen).toBeNull();
    expect(result.discarded[0].reason).toBe(NEEDS_COLD_COMPARTMENT);
  });

  it('el compartimento resta 1 kg: un Colibrí con frío lleva 1 kg, no 1,5', () => {
    const run = (payloadKg: number) =>
      chooseDrone({
        missionType: MissionType.EMERGENCY,
        quantity: 1,
        payloadKg,
        requiresCold: true,
        weatherFlyable: true,
        candidates: [
          { drone: candidate(colibri, 'colibri', true), distanceKm: 5 },
        ],
      });
    expect(run(1).chosen?.identifier).toBe('colibri');
    expect(run(1.5).discarded[0].reason).toBe(PAYLOAD_TOO_HEAVY);
  });

  it('el clima de cada tipo decide por separado (viento sobre su límite)', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      payloadKg: 0.5,
      weatherFlyable: true,
      candidates: [
        {
          drone: candidate(colibri, 'colibri'),
          distanceKm: 8,
          weather: { flyable: false, reason: 'viento' },
        },
        {
          drone: candidate(garza, 'garza'),
          distanceKm: 8,
          weather: { flyable: true, reason: null },
        },
      ],
    });
    expect(result.chosen?.identifier).toBe('garza');
    expect(result.discarded[0]).toMatchObject({
      identifier: 'colibri',
      reason: 'viento',
    });
  });

  it('dos drones del mismo tipo empatan y decide la rotación', () => {
    const rested = {
      ...candidate(garza, 'garza-1'),
      lastFlightEndedAt: new Date('2026-11-14T08:00:00Z'),
    };
    const busy = {
      ...candidate(garza, 'garza-2'),
      lastFlightEndedAt: new Date('2026-11-14T11:00:00Z'),
    };
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      payloadKg: 0.5,
      weatherFlyable: true,
      candidates: [
        { drone: busy, distanceKm: 10 },
        { drone: rested, distanceKm: 10 },
      ],
    });
    expect(result.chosen?.identifier).toBe('garza-1');
  });

  it('el peso del pedido es unidades por gramos del lote', () => {
    expect(payloadKgOf({ unitWeightG: 60 }, 5)).toBe(0.3);
    expect(payloadKgOf({ unitWeightG: null }, 10)).toBe(1);
  });
});
