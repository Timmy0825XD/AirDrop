import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { EligibilityService } from './eligibility.service';
import {
  AuthorizableOrder,
  DroneCandidate,
  DRONE_IN_MISSION,
  DRONE_MAINTENANCE,
  DRONE_OUT_OF_SERVICE,
  NOT_THE_AUTHORIZING_HUB,
  NO_CORRIDOR,
  ONLY_RECEIVED_IS_AUTHORIZED,
  PAYLOAD_TOO_HEAVY,
  PRESCRIPTION_NOT_VERIFIED,
  RANGE_TOO_SHORT,
  SCHEDULED_TOO_EARLY,
  WEATHER_BLOCKS,
  assertAuthorizingHub,
  assertCanAuthorize,
  chooseDrone,
  simulatedWeather,
} from './decision.rules';

const wingcopter = { maxPayloadKg: 6, maxRangeKm: 110 };

function candidate(
  overrides: Partial<DroneCandidate> &
    Pick<DroneCandidate, 'id' | 'identifier'>,
): DroneCandidate {
  return {
    status: DroneStatus.AVAILABLE,
    maxPayloadKg: wingcopter.maxPayloadKg,
    maxRangeKm: wingcopter.maxRangeKm,
    held: null,
    ...overrides,
  };
}

function order(overrides: Partial<AuthorizableOrder> = {}): AuthorizableOrder {
  return {
    status: OrderStatus.RECEIVED,
    missionType: MissionType.EMERGENCY,
    destinationKind: DestinationKind.PERSON,
    saleType: SaleType.OVER_THE_COUNTER,
    scheduledFor: null,
    latitude: 10.46,
    longitude: -73.25,
    originHubId: null,
    ...overrides,
  };
}

describe('simulated weather and authorize guards', () => {
  it('lets the simulated forecast fly in production', () => {
    expect(simulatedWeather()).toEqual({ flyable: true });
  });

  it('requires a checked prescription, a due date and a destination', () => {
    expect(() =>
      assertCanAuthorize(
        order({ saleType: SaleType.PRESCRIPTION }),
        '2026-10-08',
      ),
    ).toThrow(new BadRequestException(PRESCRIPTION_NOT_VERIFIED));
    expect(() =>
      assertCanAuthorize(
        order({
          saleType: SaleType.PRESCRIPTION,
          destinationKind: DestinationKind.HUB,
        }),
        '2026-10-08',
      ),
    ).not.toThrow();
    expect(() =>
      assertCanAuthorize(
        order({
          missionType: MissionType.SCHEDULED,
          scheduledFor: '2026-10-09',
        }),
        '2026-10-08',
      ),
    ).toThrow(new BadRequestException(SCHEDULED_TOO_EARLY));
    expect(() =>
      assertCanAuthorize(order({ latitude: null }), '2026-10-08'),
    ).toThrow(BadRequestException);
    expect(() =>
      assertCanAuthorize(
        order({ status: OrderStatus.PENDING_LOAD }),
        '2026-10-08',
      ),
    ).toThrow(new BadRequestException(ONLY_RECEIVED_IS_AUTHORIZED));
    expect(() => assertAuthorizingHub('origin-hub', 'other-hub')).toThrow(
      new ForbiddenException(NOT_THE_AUTHORIZING_HUB),
    );
  });
});

describe('chooseDrone', () => {
  const service = new EligibilityService();

  it('discards maintenance, payload, range, weather and a blocked corridor', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      weatherFlyable: true,
      candidates: [
        {
          drone: candidate({
            id: 'maint',
            identifier: 'M-1',
            status: DroneStatus.MAINTENANCE,
          }),
          distanceKm: 4,
        },
        {
          drone: candidate({
            id: 'down',
            identifier: 'O-1',
            status: DroneStatus.OUT_OF_SERVICE,
          }),
          distanceKm: 4,
        },
        {
          drone: candidate({ id: 'far', identifier: 'F-1' }),
          distanceKm: 60,
        },
        {
          drone: candidate({ id: 'blocked', identifier: 'B-1' }),
          distanceKm: null,
        },
      ],
    });
    expect(result.chosen).toBeNull();
    expect(result.discarded.map((row) => row.reason)).toEqual([
      DRONE_MAINTENANCE,
      DRONE_OUT_OF_SERVICE,
      RANGE_TOO_SHORT,
      NO_CORRIDOR,
    ]);
  });

  it('discards a load above 6 kg', () => {
    const result = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 13,
      weatherFlyable: true,
      candidates: [
        { drone: candidate({ id: 'heavy', identifier: 'H-1' }), distanceKm: 4 },
      ],
    });
    expect(result.chosen).toBeNull();
    expect(result.discarded[0].reason).toBe(PAYLOAD_TOO_HEAVY);
  });

  it('discards every drone when the simulated weather blocks the flight', () => {
    const result = service.choose({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      weatherFlyable: false,
      candidates: [
        { drone: candidate({ id: 'free', identifier: 'A-1' }), distanceKm: 3 },
      ],
    });
    expect(result.chosen).toBeNull();
    expect(result.discarded[0].reason).toBe(WEATHER_BLOCKS);
  });

  it('keeps the shorter free corridor and breaks ties by identifier', () => {
    const result = chooseDrone({
      missionType: MissionType.SCHEDULED,
      quantity: 12,
      weatherFlyable: true,
      candidates: [
        { drone: candidate({ id: 'long', identifier: 'A-1' }), distanceKm: 20 },
        { drone: candidate({ id: 'b', identifier: 'B-1' }), distanceKm: 8 },
        { drone: candidate({ id: 'a', identifier: 'A-2' }), distanceKm: 8 },
      ],
    });
    expect(result.chosen).toMatchObject({
      droneId: 'a',
      distanceKm: 8,
      preemptsOrderId: null,
    });
  });

  it('lets an emergency take a scheduled reservation only when no free drone fits', () => {
    const reserved = candidate({
      id: 'reserved',
      identifier: 'A-1',
      status: DroneStatus.IN_MISSION,
      held: {
        orderId: 'scheduled-order',
        missionType: MissionType.SCHEDULED,
        status: OrderStatus.PENDING_LOAD,
      },
    });
    const free = candidate({ id: 'free', identifier: 'B-9' });
    const withFree = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      weatherFlyable: true,
      candidates: [
        { drone: reserved, distanceKm: 4 },
        { drone: free, distanceKm: 4 },
      ],
    });
    expect(withFree.chosen).toMatchObject({
      droneId: 'free',
      preemptsOrderId: null,
    });

    const onlyReserved = chooseDrone({
      missionType: MissionType.EMERGENCY,
      quantity: 1,
      weatherFlyable: true,
      candidates: [{ drone: reserved, distanceKm: 4 }],
    });
    expect(onlyReserved.chosen).toMatchObject({
      droneId: 'reserved',
      preemptsOrderId: 'scheduled-order',
    });
  });

  it('does not take a drone held by another emergency or by a flight already moving', () => {
    const reasons = [
      candidate({
        id: 'other',
        identifier: 'E-1',
        status: DroneStatus.IN_MISSION,
        held: {
          orderId: 'emergency-order',
          missionType: MissionType.EMERGENCY,
          status: OrderStatus.PENDING_LOAD,
        },
      }),
      candidate({
        id: 'flying',
        identifier: 'F-1',
        status: DroneStatus.IN_MISSION,
        held: {
          orderId: 'flying-order',
          missionType: MissionType.SCHEDULED,
          status: OrderStatus.IN_FLIGHT,
        },
      }),
    ].map(
      (drone) =>
        chooseDrone({
          missionType: MissionType.EMERGENCY,
          quantity: 1,
          weatherFlyable: true,
          candidates: [{ drone, distanceKm: 4 }],
        }).discarded[0].reason,
    );
    expect(reasons).toEqual([DRONE_IN_MISSION, DRONE_IN_MISSION]);
  });
});
