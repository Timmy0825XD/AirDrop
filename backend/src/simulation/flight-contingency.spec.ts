import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { LaunchIncidentDto } from '../control/dto/launch-incident.dto';
import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { IncidentKind } from '../common/enums/incident-kind.enum';
import { IncidentOutcome } from '../common/enums/incident-outcome.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { incidentDraft } from '../control/timeline.rules';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import * as routingRules from '../routing/routing.rules';
import { PlannedCorridor, isInsideGeofence } from '../routing/routing.rules';
import {
  DRONE_NOT_FLYING,
  FlightClockService,
  NO_COLD_LOAD,
} from './flight-clock.service';
import { FlightPhase, initialProgress } from './simulation.rules';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const DRONE_ID = '33333333-3333-4333-8333-333333333333';
const HUB = { latitude: 10.46, longitude: -73.3 };

/** Recta de unos 11 km hacia el este desde la central. */
const straight: PlannedCorridor = {
  altitudeM: 100,
  distanceKm: 10.94,
  coordinates: [
    [-73.3, 10.46],
    [-73.2, 10.46],
  ],
};

function build(polygons: GeoJsonPolygon[] = []) {
  const orders = {
    findOne: jest.fn().mockResolvedValue({
      id: ORDER_ID,
      status: OrderStatus.IN_FLIGHT,
      medicationName: 'Insulina',
      saleType: 'otc',
      quantity: 1,
      dispatchedLot: 'L-0001',
      dispatchedLotExpiresOn: '2027-01-01',
    }),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
    count: jest.fn().mockResolvedValue(0),
    manager: {},
  };
  const drones = { update: jest.fn().mockResolvedValue(undefined) };
  const missions = {
    findOne: jest.fn().mockResolvedValue(null),
    create: jest.fn((row: object) => row),
    save: jest.fn((row: object) => Promise.resolve(row)),
    update: jest.fn().mockResolvedValue(undefined),
  };
  const routes = {
    loadPolygons: jest.fn().mockResolvedValue(polygons),
    replaceLeg: jest.fn().mockResolvedValue(undefined),
    saveReturn: jest.fn().mockResolvedValue(undefined),
    findReturn: jest.fn().mockResolvedValue(null),
  };
  const telemetry = {
    publishFlight: jest.fn().mockResolvedValue(undefined),
    forgetFlight: jest.fn().mockResolvedValue(undefined),
  };
  const notifications = {
    statusChanged: jest.fn().mockResolvedValue(undefined),
    alert: jest.fn().mockResolvedValue(undefined),
    rerouted: jest.fn().mockResolvedValue(undefined),
  };
  const incidents = {
    record: jest.fn(
      (input: {
        orderId: string;
        droneId: string;
        hubId: string;
        kind: IncidentKind;
        leg: RouteLeg;
        protocol: ContingencyProtocol;
        position: { latitude: number; longitude: number };
        batteryPercent: number;
        packageOf: object | null;
      }) =>
        Promise.resolve({
          id: 'incident-1',
          orderId: input.orderId,
          droneId: input.droneId,
          hubId: input.hubId,
          kind: input.kind,
          severity: 'major',
          leg: input.leg,
          protocol: input.protocol,
          outcome: IncidentOutcome.CONTINUED,
          latitude: input.position.latitude,
          longitude: input.position.longitude,
          batteryPercent: input.batteryPercent,
          landingLatitude: null,
          landingLongitude: null,
          rescueDueAt: null,
          packageQuantity: null,
          occurredAt: new Date(),
          resolvedAt: null,
        }),
    ),
    setLanding: jest.fn().mockResolvedValue(undefined),
    grounded: jest.fn().mockResolvedValue(null),
    returnedHome: jest.fn().mockResolvedValue(undefined),
    lose: jest.fn().mockResolvedValue(false),
  };
  const service = new FlightClockService(
    orders as never,
    drones as never,
    missions as never,
    routes as never,
    telemetry as never,
    notifications as never,
    { notifyUser: jest.fn(), notifyHubDispatchers: jest.fn() } as never,
    { active: () => [] } as never,
    incidents as never,
  );
  const aborted = jest.fn().mockResolvedValue(undefined);
  service.onMissionAborted(aborted);
  return {
    service,
    orders,
    drones,
    routes,
    notifications,
    incidents,
    telemetry,
    aborted,
  };
}

function fly(
  built: ReturnType<typeof build>,
  options: {
    leg?: RouteLeg;
    keepStatus?: boolean;
    cruiseKm: number;
    batteryPercent: number;
    cold?: boolean;
  },
) {
  built.service['active'].set(ORDER_ID, {
    leg: options.leg ?? RouteLeg.OUTBOUND,
    keepStatus: options.keepStatus ?? false,
    orderId: ORDER_ID,
    droneId: DRONE_ID,
    hubId: 'hub-1',
    hub: HUB,
    identifier: 'WG-198-001',
    quantity: 1,
    requiresColdChain: options.cold ?? false,
    corridor: straight,
    model: { maxSpeedKmh: 150, maxRangeKm: 110 },
    progress: {
      ...initialProgress(),
      phase: FlightPhase.CRUISE,
      cruiseKm: options.cruiseKm,
      batteryPercent: options.batteryPercent,
      orderStatus: options.keepStatus
        ? OrderStatus.DELIVERED
        : OrderStatus.IN_FLIGHT,
    },
    loadConfirmedAt: new Date('2026-11-06T14:00:00.000Z'),
    departure: null,
  });
  return built.service['active'].get(ORDER_ID)!;
}

/** Lo que el reloj mandó a guardar en el primer incidente. */
function recorded(built: ReturnType<typeof build>) {
  const [input] = built.incidents.record.mock.calls[0] as [
    { packageOf: object | null },
  ];
  return input;
}

/** Ticks de 2 s hasta que el dron toque tierra. */
async function untilLanded(service: FlightClockService): Promise<void> {
  for (let tick = 0; tick < 500 && service['active'].has(ORDER_ID); tick += 1) {
    await service['tick'](ORDER_ID);
  }
}

describe('Viento sobre el límite de ida: vuelve a la central (RF-34, RF-35)', () => {
  it('da la vuelta con el paquete, el pedido pasa a returning y la ruta nueva sale de donde iba', async () => {
    const built = build();
    const session = fly(built, { cruiseKm: 4, batteryPercent: 70 });
    await built.service['handleIncident'](session, IncidentKind.WIND_LIMIT);
    expect(built.incidents.record).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: IncidentKind.WIND_LIMIT,
        protocol: ContingencyProtocol.RETURN_TO_HUB,
        leg: RouteLeg.OUTBOUND,
      }),
    );
    // El paquete va a bordo: queda copiado en el incidente.
    expect(recorded(built).packageOf).not.toBeNull();
    const now = built.service['active'].get(ORDER_ID)!;
    expect(now.leg).toBe(RouteLeg.RETURN);
    expect(now.progress.orderStatus).toBe(OrderStatus.RETURNING);
    expect(now.progress.cruiseKm).toBe(0);
    expect(now.corridor.coordinates.at(-1)).toEqual([
      HUB.longitude,
      HUB.latitude,
    ]);
    expect(now.corridor.distanceKm).toBeCloseTo(4, 0);
    expect(built.routes.saveReturn).toHaveBeenCalled();
    expect(built.orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID },
      { status: OrderStatus.RETURNING },
    );
  });

  it('al aterrizar en la central el paquete queda en cuarentena y sale otro dron', async () => {
    const built = build();
    const session = fly(built, { cruiseKm: 4, batteryPercent: 70 });
    await built.service['handleIncident'](session, IncidentKind.WIND_LIMIT);
    await untilLanded(built.service);
    expect(built.orders.update).toHaveBeenCalledWith(
      { id: ORDER_ID },
      { status: OrderStatus.RETURNED },
    );
    expect(built.drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      expect.objectContaining({ status: DroneStatus.AVAILABLE }),
    );
    expect(built.incidents.returnedHome).toHaveBeenCalledWith('incident-1');
    // El dron nuevo no retoma el vuelo del que volvió.
    expect(built.telemetry.forgetFlight).toHaveBeenCalledWith(ORDER_ID);
    expect(built.aborted).toHaveBeenCalledWith(ORDER_ID);
  });
});

describe('Sin batería para nada: aterrizaje de emergencia (RF-34)', () => {
  it('baja donde va, el dron queda en tierra fuera de base y el pedido vuelve al motor', async () => {
    const built = build();
    const session = fly(built, { cruiseKm: 5, batteryPercent: 8 });
    await built.service['handleIncident'](
      session,
      IncidentKind.BATTERY_CRITICAL,
    );
    expect(built.incidents.record).toHaveBeenCalledWith(
      expect.objectContaining({
        protocol: ContingencyProtocol.EMERGENCY_LANDING,
      }),
    );
    expect(built.routes.replaceLeg).toHaveBeenCalledWith(
      ORDER_ID,
      RouteLeg.OUTBOUND,
      expect.objectContaining({ altitudeM: 100 }),
    );
    expect(built.incidents.setLanding).toHaveBeenCalled();
    await untilLanded(built.service);
    // Bajar de emergencia no es llegar: el pedido no pasa a esperar el código.
    expect(built.orders.update).not.toHaveBeenCalledWith(
      { id: ORDER_ID },
      { status: OrderStatus.AWAITING_DELIVERY },
    );
    expect(built.drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      expect.objectContaining({ status: DroneStatus.GROUNDED }),
    );
    const [, landing] = built.incidents.grounded.mock.calls[0] as [
      string,
      { latitude: number; longitude: number },
    ];
    expect(landing.latitude).toBeCloseTo(10.46, 4);
    expect(landing.longitude).toBeGreaterThan(-73.26);
    expect(landing.longitude).toBeLessThan(-73.25);
    expect(built.aborted).toHaveBeenCalledWith(ORDER_ID);
  });

  it('dentro de una tormenta baja afuera de ella', async () => {
    const storm: GeoJsonPolygon = {
      type: 'Polygon',
      coordinates: [
        [
          [-73.26, 10.455],
          [-73.25, 10.455],
          [-73.25, 10.465],
          [-73.26, 10.465],
          [-73.26, 10.455],
        ],
      ],
    };
    const built = build([storm]);
    const session = fly(built, { cruiseKm: 4.9, batteryPercent: 6 });
    await built.service['handleIncident'](
      session,
      IncidentKind.BATTERY_CRITICAL,
    );
    const [, landing] = built.incidents.setLanding.mock.calls[0] as [
      string,
      { latitude: number; longitude: number },
    ];
    expect(isInsideGeofence(landing, [storm])).toBe(false);
  });

  it('de regreso tras entregar, el dron cae pero el pedido ya entregado no se toca', async () => {
    const built = build();
    const session = fly(built, {
      leg: RouteLeg.RETURN,
      keepStatus: true,
      cruiseKm: 2,
      batteryPercent: 4,
    });
    await built.service['handleIncident'](
      session,
      IncidentKind.BATTERY_CRITICAL,
    );
    expect(recorded(built).packageOf).toBeNull();
    await untilLanded(built.service);
    expect(built.drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      expect.objectContaining({ status: DroneStatus.GROUNDED }),
    );
    expect(built.aborted).not.toHaveBeenCalled();
  });

  it('un segundo incidente mientras baja no cambia nada', async () => {
    const built = build();
    const session = fly(built, { cruiseKm: 5, batteryPercent: 8 });
    await built.service['handleIncident'](
      session,
      IncidentKind.BATTERY_CRITICAL,
    );
    await built.service['handleIncident'](
      built.service['active'].get(ORDER_ID)!,
      IncidentKind.WIND_LIMIT,
    );
    expect(built.incidents.record).toHaveBeenCalledTimes(1);
  });
});

describe('Batería crítica cerca de la central (decisión del 2026-11-06)', () => {
  it('de regreso a 500 m sigue y aterriza en la central', async () => {
    const built = build();
    const session = fly(built, {
      leg: RouteLeg.RETURN,
      keepStatus: true,
      cruiseKm: 10.44,
      batteryPercent: 19.9,
    });
    await built.service['handleIncident'](
      session,
      IncidentKind.BATTERY_CRITICAL,
    );
    expect(built.incidents.record).toHaveBeenCalledWith(
      expect.objectContaining({ protocol: ContingencyProtocol.CONTINUE }),
    );
    expect(built.routes.replaceLeg).not.toHaveBeenCalled();
  });
});

describe('Ruta bloqueada en vuelo (RF-33 → RF-34)', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('sin camino seguro, recheckRoutes aplica el protocolo en vez de solo avisar', async () => {
    jest
      .spyOn(routingRules, 'rerouteFromPosition')
      .mockReturnValue({ kind: 'blocked' });
    const built = build();
    fly(built, { cruiseKm: 2, batteryPercent: 80 });
    await built.service.recheckRoutes();
    expect(built.notifications.rerouted).toHaveBeenCalledWith(
      expect.objectContaining({ outcome: 'blocked' }),
    );
    // No puede seguir sin camino; la central sí se alcanza: vuelve.
    expect(built.incidents.record).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: IncidentKind.ROUTE_BLOCKED,
        protocol: ContingencyProtocol.RETURN_TO_HUB,
      }),
    );
    expect(built.service['active'].get(ORDER_ID)!.leg).toBe(RouteLeg.RETURN);
  });
});

describe('El incidente en la línea de tiempo (RF-39)', () => {
  const base = {
    orderId: ORDER_ID,
    droneId: DRONE_ID,
    hubId: 'hub-1',
    kind: IncidentKind.WIND_LIMIT,
    leg: RouteLeg.OUTBOUND,
    protocol: ContingencyProtocol.RETURN_TO_HUB,
    outcome: IncidentOutcome.RETURNING,
    latitude: 10.46,
    longitude: -73.26,
    batteryPercent: 63.4,
    landingLatitude: null,
    landingLongitude: null,
    packageOnBoard: true,
  };

  it('cuenta qué pasó y qué decidió el sistema, sin el medicamento', () => {
    const draft = incidentDraft(base, 'WG-198-001');
    expect(draft).toMatchObject({
      kind: 'alert',
      severity: 'danger',
      title:
        'WG-198-001: viento sobre el límite; vuelve a la central con el paquete',
      latitude: 10.46,
    });
    expect(draft.detail).toContain('Batería 63 %');
  });

  it('en tierra dice cuánto falta para el rescate y se enfoca donde bajó', () => {
    const draft = incidentDraft(
      {
        ...base,
        protocol: ContingencyProtocol.EMERGENCY_LANDING,
        outcome: IncidentOutcome.GROUNDED,
        landingLatitude: 10.47,
        landingLongitude: -73.25,
      },
      'WG-198-001',
      22,
    );
    expect(draft).toMatchObject({
      title: 'WG-198-001 aterrizó de emergencia',
      detail: 'El rescate llega en unos 22 min.',
      latitude: 10.47,
      longitude: -73.25,
    });
  });

  it('al rescatarlo avisa en verde que entra a mantenimiento', () => {
    expect(
      incidentDraft(
        { ...base, outcome: IncidentOutcome.RESCUED },
        'WG-198-001',
      ),
    ).toMatchObject({
      severity: 'success',
      title: 'WG-198-001 rescatado: entra a mantenimiento',
    });
  });
});

describe('Catálogo de incidentes de la consola (RF-34, CU-38)', () => {
  it('un dron que no está en vuelo no recibe el evento', async () => {
    const built = build();
    await expect(
      built.service.launchIncident(DRONE_ID, IncidentKind.MOTOR_FAILURE),
    ).rejects.toThrow(new BadRequestException(DRONE_NOT_FLYING));
  });

  it('falla de un motor: más consumo y menos velocidad; con batería de sobra sigue', async () => {
    const built = build();
    fly(built, { cruiseKm: 2, batteryPercent: 90 });
    const incident = await built.service.launchIncident(
      DRONE_ID,
      IncidentKind.MOTOR_FAILURE,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.CONTINUE);
    const progress = built.service['active'].get(ORDER_ID)!.progress;
    expect(progress.burnFactor).toBeCloseTo(1.15, 6);
    expect(progress.speedFactor).toBeCloseTo(0.9, 6);
  });

  it('los efectos se acumulan: batería degradada y choque leve', async () => {
    const built = build();
    fly(built, { cruiseKm: 2, batteryPercent: 90 });
    await built.service.launchIncident(DRONE_ID, IncidentKind.BATTERY_DEGRADED);
    await built.service.launchIncident(DRONE_ID, IncidentKind.COLLISION_MINOR);
    const progress = built.service['active'].get(ORDER_ID)!.progress;
    expect(progress.burnFactor).toBeCloseTo(1.25 * 1.1, 6);
  });

  it('con el consumo ya subido, la misma batería que antes alcanzaba ahora no alcanza para entregar', async () => {
    const built = build();
    // Terminar pide ~31,4 %: con 52 % sobra la reserva del 20 %. Con +25 %
    // pide ~39,3 % y ya no; volver a la central sí alcanza.
    fly(built, { cruiseKm: 0.5, batteryPercent: 52 });
    const incident = await built.service.launchIncident(
      DRONE_ID,
      IncidentKind.BATTERY_DEGRADED,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.RETURN_TO_HUB);
  });

  it('dos motores o GPS sin respaldo: aterrizaje de emergencia; GPS leve sigue', async () => {
    for (const [kind, protocol] of [
      [IncidentKind.DUAL_MOTOR_FAILURE, ContingencyProtocol.EMERGENCY_LANDING],
      [IncidentKind.GPS_LOSS_MAJOR, ContingencyProtocol.EMERGENCY_LANDING],
      [IncidentKind.GPS_LOSS_MINOR, ContingencyProtocol.CONTINUE],
    ] as const) {
      const built = build();
      fly(built, { cruiseKm: 2, batteryPercent: 90 });
      const incident = await built.service.launchIncident(DRONE_ID, kind);
      expect(incident.protocol).toBe(protocol);
    }
  });

  it('sin enlace vuelve solo a la central, marcado; el enlace vuelve al aterrizar', async () => {
    const built = build();
    fly(built, { cruiseKm: 3, batteryPercent: 90 });
    const incident = await built.service.launchIncident(
      DRONE_ID,
      IncidentKind.LINK_LOSS,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.RETURN_TO_HUB);
    const session = built.service['active'].get(ORDER_ID)!;
    expect(session.progress.linkLost).toBe(true);
    await untilLanded(built.service);
    const published = built.telemetry.publishFlight.mock.calls.map(
      ([flight]) => flight as { linkLost?: boolean; phase: FlightPhase },
    );
    expect(published.some((flight) => flight.linkLost === true)).toBe(true);
    const last = published.at(-1)!;
    expect(last.phase).toBe(FlightPhase.LANDED);
    expect(last.linkLost).toBe(false);
  });

  it('falla de la refrigeración: sin carga fría no aplica; con ella sigue y la carga empieza a calentarse', async () => {
    const dry = build();
    fly(dry, { cruiseKm: 2, batteryPercent: 90 });
    await expect(
      dry.service.launchIncident(DRONE_ID, IncidentKind.COOLING_FAILURE),
    ).rejects.toThrow(new BadRequestException(NO_COLD_LOAD));
    const cold = build();
    fly(cold, { cruiseKm: 2, batteryPercent: 90, cold: true });
    const incident = await cold.service.launchIncident(
      DRONE_ID,
      IncidentKind.COOLING_FAILURE,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.CONTINUE);
    expect(
      cold.service['active'].get(ORDER_ID)!.progress.coldChainExcursionAtMs,
    ).not.toBeNull();
  });

  it('choque grave: cae donde va, queda en tierra y el pedido vuelve al motor', async () => {
    const built = build();
    fly(built, { cruiseKm: 5, batteryPercent: 90 });
    const incident = await built.service.launchIncident(
      DRONE_ID,
      IncidentKind.COLLISION_MAJOR,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.CRASH);
    expect(built.service['active'].has(ORDER_ID)).toBe(false);
    expect(built.drones.update).toHaveBeenCalledWith(
      { id: DRONE_ID },
      expect.objectContaining({ status: DroneStatus.GROUNDED }),
    );
    const [, at] = built.incidents.grounded.mock.calls[0] as [
      string,
      { latitude: number; longitude: number },
    ];
    expect(at.latitude).toBeCloseTo(10.46, 4);
    expect(built.aborted).toHaveBeenCalledWith(ORDER_ID);
  });

  it('dron perdido: sin rescate, fuera de servicio ya y el pedido vuelve al motor', async () => {
    const built = build();
    fly(built, { cruiseKm: 5, batteryPercent: 90 });
    const incident = await built.service.launchIncident(
      DRONE_ID,
      IncidentKind.DRONE_LOST,
    );
    expect(incident.protocol).toBe(ContingencyProtocol.LOST);
    expect(built.incidents.lose).toHaveBeenCalledWith('incident-1');
    expect(built.service['active'].has(ORDER_ID)).toBe(false);
    expect(built.aborted).toHaveBeenCalledWith(ORDER_ID);
  });

  it('de regreso vacío, perder el dron no toca el pedido entregado', async () => {
    const built = build();
    fly(built, {
      leg: RouteLeg.RETURN,
      keepStatus: true,
      cruiseKm: 2,
      batteryPercent: 60,
    });
    await built.service.launchIncident(DRONE_ID, IncidentKind.DRONE_LOST);
    expect(built.aborted).not.toHaveBeenCalled();
    expect(built.telemetry.forgetFlight).toHaveBeenCalledWith(ORDER_ID);
  });
});

describe('El catálogo en la línea de tiempo y en la consola (RF-39, CU-38)', () => {
  const facts = {
    orderId: ORDER_ID,
    droneId: DRONE_ID,
    hubId: 'hub-1',
    kind: IncidentKind.COLLISION_MAJOR,
    leg: RouteLeg.OUTBOUND,
    protocol: ContingencyProtocol.CRASH,
    outcome: IncidentOutcome.LANDING,
    latitude: 10.46,
    longitude: -73.25,
    batteryPercent: 70,
    landingLatitude: null,
    landingLongitude: null,
    packageOnBoard: true,
  };

  it('el choque grave cae donde va y, al recuperarlo, queda fuera de servicio', () => {
    expect(incidentDraft(facts, 'WG-1').title).toBe(
      'WG-1: choque grave; cae donde va',
    );
    expect(
      incidentDraft({ ...facts, outcome: IncidentOutcome.RESCUED }, 'WG-1'),
    ).toMatchObject({
      title: 'Recuperaron WG-1: queda fuera de servicio',
      detail: 'El paquete se perdió.',
    });
  });

  it('el dron perdido se cuenta en rojo', () => {
    expect(
      incidentDraft(
        {
          ...facts,
          kind: IncidentKind.DRONE_LOST,
          protocol: ContingencyProtocol.LOST,
          outcome: IncidentOutcome.LOST,
        },
        'WG-1',
      ),
    ).toMatchObject({
      severity: 'danger',
      title: 'Se perdió el rastro de WG-1',
    });
  });

  it('la consola solo lanza incidentes del catálogo, no los que detecta el reloj', async () => {
    const errors = async (kind: string) =>
      (await validate(plainToInstance(LaunchIncidentDto, { kind }))).length;
    await expect(errors(IncidentKind.MOTOR_FAILURE)).resolves.toBe(0);
    await expect(errors(IncidentKind.WIND_LIMIT)).resolves.toBe(1);
    await expect(errors('meteorito')).resolves.toBe(1);
  });
});
