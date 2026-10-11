import { UserRole } from '../common/enums/user-role.enum';
import { FlightPhase, LiveFlight } from '../simulation/simulation.rules';
import { presentTelemetry, telemetryAccess } from './telemetry.rules';

const flight = {
  orderId: '11111111-1111-4111-8111-111111111111',
  droneId: '33333333-3333-4333-8333-333333333333',
  identifier: 'WC-01',
  latitude: 10.47,
  longitude: -73.26,
  altitudeM: 100,
  speedKmh: 150,
  batteryPercent: 80,
  payloadKg: 0.5,
  temperatureC: null,
  latencyMs: 40,
  phase: FlightPhase.CRUISE,
  leg: 'outbound',
  status: 'in_flight',
  etaSeconds: 90,
  progress: {},
} as LiveFlight;

describe('telemetryAccess', () => {
  const order = {
    requesterId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    originHubId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  };

  it('gives the requester the map and the operator the full packet with alerts', () => {
    expect(
      telemetryAccess(
        { id: order.requesterId, role: UserRole.REQUESTER, hubIds: [] },
        order,
      ),
    ).toEqual({ view: 'map', alerts: false });
    expect(
      telemetryAccess(
        {
          id: 'operator',
          role: UserRole.FLEET_OPERATOR,
          hubIds: [order.originHubId],
        },
        order,
      ),
    ).toEqual({ view: 'full', alerts: true });
    expect(
      telemetryAccess(
        {
          id: 'dispatcher',
          role: UserRole.DISPATCHER,
          hubIds: [order.originHubId],
        },
        order,
      ),
    ).toEqual({ view: 'full', alerts: false });
    expect(
      telemetryAccess(
        { id: 'other', role: UserRole.REQUESTER, hubIds: [] },
        order,
      ),
    ).toBeNull();
  });

  it('hides battery, payload, temperature and latency from the map view', () => {
    const map = presentTelemetry(flight, 'map');
    expect(map).not.toHaveProperty('batteryPercent');
    expect(map).not.toHaveProperty('payloadKg');
    expect(map).not.toHaveProperty('temperatureC');
    expect(map).not.toHaveProperty('latencyMs');
    expect(presentTelemetry(flight, 'full')).toMatchObject({
      batteryPercent: 80,
      payloadKg: 0.5,
      temperatureC: null,
      latencyMs: 40,
    });
  });
});
