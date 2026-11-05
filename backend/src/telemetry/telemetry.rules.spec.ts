import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { FlightPhase, LiveFlight } from '../simulation/simulation.rules';
import {
  concernsFleetMap,
  isFlightEnd,
  leavesFleetMap,
  presentTelemetry,
  receivesHubFlights,
  telemetryAccess,
} from './telemetry.rules';

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
    destinationHubId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  };

  it('gives the destination dispatcher the map only', () => {
    const transfer = { ...order, requesterId: null };
    expect(
      telemetryAccess(
        {
          id: 'receiver',
          role: UserRole.DISPATCHER,
          hubIds: [order.destinationHubId],
        },
        transfer,
      ),
    ).toEqual({ view: 'map', alerts: false });
    expect(
      telemetryAccess(
        {
          id: 'receiver',
          role: UserRole.FLEET_OPERATOR,
          hubIds: [order.destinationHubId],
        },
        transfer,
      ),
    ).toBeNull();
  });

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

describe('Mapa de la flota en la sala de la central', () => {
  const flight = (leg: RouteLeg, phase: FlightPhase) =>
    ({ leg, phase }) as unknown as LiveFlight;

  it('solo el operador recibe el mapa de la flota', () => {
    expect(receivesHubFlights(UserRole.FLEET_OPERATOR)).toBe(true);
    expect(receivesHubFlights(UserRole.DISPATCHER)).toBe(false);
    expect(receivesHubFlights(UserRole.ADMIN)).toBe(false);
  });

  it('un pedido que toma o devuelve un dron entra al mapa', () => {
    expect(concernsFleetMap(OrderStatus.PENDING_LOAD, false)).toBe(true);
    expect(concernsFleetMap(OrderStatus.RETURNED, false)).toBe(true);
  });

  it('un pedido sin dron no le importa al operador', () => {
    expect(concernsFleetMap(OrderStatus.RECEIVED, false)).toBe(false);
    expect(concernsFleetMap(OrderStatus.REJECTED, false)).toBe(false);
  });

  it('si ya iba en el mapa, soltar el dron antes de despegar sí avisa', () => {
    expect(concernsFleetMap(OrderStatus.REASSIGNED, true)).toBe(true);
    expect(leavesFleetMap(OrderStatus.REASSIGNED)).toBe(true);
  });

  it('entregado sigue en el mapa: el dron todavía vuelve', () => {
    expect(leavesFleetMap(OrderStatus.DELIVERED)).toBe(false);
    expect(leavesFleetMap(OrderStatus.RETURNED)).toBe(true);
  });

  it('el vuelo termina al aterrizar de regreso, no al aterrizar en destino', () => {
    expect(isFlightEnd(flight(RouteLeg.RETURN, FlightPhase.LANDED))).toBe(true);
    expect(isFlightEnd(flight(RouteLeg.OUTBOUND, FlightPhase.LANDED))).toBe(
      false,
    );
    expect(isFlightEnd(flight(RouteLeg.RETURN, FlightPhase.CRUISE))).toBe(
      false,
    );
  });
});
