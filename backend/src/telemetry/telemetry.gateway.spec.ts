import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { TelemetryAccessService } from './telemetry-access.service';
import { TelemetryGateway } from './telemetry.gateway';
import { TelemetryPublisher } from './telemetry.publisher';

const ORDER_ID = '11111111-1111-4111-8111-111111111111';
const USER_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

function build(findUser: () => Promise<User | null>) {
  const jwt = { verify: jest.fn().mockReturnValue({ sub: USER_ID }) };
  const access = {
    findUser: jest.fn(findUser),
    resolve: jest.fn().mockResolvedValue({ view: 'map', alerts: false }),
    originHubOf: jest.fn().mockResolvedValue(null),
  };
  const publisher = { readFlight: jest.fn().mockResolvedValue(null) };
  const gateway = new TelemetryGateway(
    jwt as unknown as JwtService,
    access as unknown as TelemetryAccessService,
    publisher as unknown as TelemetryPublisher,
  );
  return { gateway, access };
}

function socket(disconnect = jest.fn(), id = 'socket-1') {
  return {
    id,
    handshake: { auth: { token: 'token' } },
    disconnect,
    join: jest.fn().mockResolvedValue(undefined),
    emit: jest.fn(),
  } as unknown as Socket;
}

describe('TelemetryGateway.subscribe', () => {
  it('waits for the token check when subscribe arrives right after connecting', async () => {
    let release: (user: User) => void = () => undefined;
    const { gateway } = build(
      () => new Promise<User>((resolve) => (release = resolve)),
    );
    const client = socket();

    // Nest no espera handleConnection: el subscribe llega antes del usuario.
    const connected = gateway.handleConnection(client);
    const reply = gateway.subscribe(client, { orderId: ORDER_ID });
    release({ id: USER_ID, status: UserStatus.ACTIVE } as User);
    await connected;

    await expect(reply).resolves.toEqual({
      event: 'subscribed',
      data: { orderId: ORDER_ID },
    });
  });

  it('rejects the subscription when the token has no active user', async () => {
    const { gateway, access } = build(() => Promise.resolve(null));
    const disconnect = jest.fn();
    const client = socket(disconnect);

    await gateway.handleConnection(client);
    const reply = await gateway.subscribe(client, { orderId: ORDER_ID });

    expect(disconnect).toHaveBeenCalledWith(true);
    expect(access.resolve).not.toHaveBeenCalled();
    expect(reply).toEqual({
      event: 'error',
      data: { message: 'El pedido no existe.' },
    });
  });
});

describe('TelemetryGateway.subscribeHub', () => {
  const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

  const joinOf = (client: Socket) =>
    (client as unknown as { join: jest.Mock }).join;

  function staff(role: UserRole, hubId: string): User {
    return {
      id: USER_ID,
      role,
      status: UserStatus.ACTIVE,
      hubAssignments: [{ hubId }],
    } as unknown as User;
  }

  it('joins the room of a hub assigned to the dispatcher', async () => {
    const { gateway } = build(() =>
      Promise.resolve(staff(UserRole.DISPATCHER, HUB_ID)),
    );
    const client = socket();
    await gateway.handleConnection(client);
    const reply = await gateway.subscribeHub(client, { hubId: HUB_ID });
    expect(joinOf(client)).toHaveBeenCalledWith(`hub:${HUB_ID}`);
    expect(reply).toEqual({ event: 'subscribed-hub', data: { hubId: HUB_ID } });
  });

  it('rejects a hub that is not assigned, and a requester', async () => {
    const other = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    for (const user of [
      staff(UserRole.DISPATCHER, other),
      staff(UserRole.REQUESTER, HUB_ID),
    ]) {
      const { gateway } = build(() => Promise.resolve(user));
      const client = socket();
      await gateway.handleConnection(client);
      const reply = await gateway.subscribeHub(client, { hubId: HUB_ID });
      expect(joinOf(client)).not.toHaveBeenCalled();
      expect(reply).toEqual({
        event: 'error',
        data: { message: 'La central no está asignada a tu cuenta.' },
      });
    }
  });
});

describe('TelemetryGateway alertas por central (CU-32)', () => {
  const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const event = {
    type: 'alert' as const,
    orderId: ORDER_ID,
    droneId: '33333333-3333-4333-8333-333333333333',
    kind: 'cold_chain' as const,
    message: 'La temperatura de la carga salió del rango de 2 a 8 °C.',
  };

  async function joined(role: UserRole, id: string) {
    const user = {
      id: USER_ID,
      role,
      status: UserStatus.ACTIVE,
      hubAssignments: [{ hubId: HUB_ID }],
    } as unknown as User;
    const built = build(() => Promise.resolve(user));
    const client = socket(jest.fn(), id);
    await built.gateway.handleConnection(client);
    await built.gateway.subscribeHub(client, { hubId: HUB_ID });
    return { ...built, client };
  }

  it('el operador en la sala de la central recibe la alerta; el despachador no', async () => {
    const operator = await joined(UserRole.FLEET_OPERATOR, 'op');
    const dispatcher = await joined(UserRole.DISPATCHER, 'disp');
    // Un mismo gateway con los dos sockets: se copian los estados.
    const gateway = operator.gateway;
    gateway['clients'].set('disp', dispatcher.gateway['clients'].get('disp')!);
    operator.access.originHubOf.mockResolvedValue(HUB_ID);
    gateway.server = {
      to: () => ({ emit: jest.fn() }),
      in: (name: string) => ({
        fetchSockets: () =>
          Promise.resolve(
            name === `hub:${HUB_ID}`
              ? [operator.client, dispatcher.client]
              : [],
          ),
      }),
    } as never;

    await gateway['dispatch'](event);

    expect(emitOf(operator.client)).toHaveBeenCalledWith(
      'alert',
      expect.objectContaining({ kind: 'cold_chain', orderId: ORDER_ID }),
    );
    expect(emitOf(dispatcher.client)).not.toHaveBeenCalled();
  });

  it('quien ya sigue el pedido con alertas no la recibe dos veces', async () => {
    const operator = await joined(UserRole.FLEET_OPERATOR, 'op');
    operator.access.originHubOf.mockResolvedValue(HUB_ID);
    operator.gateway['clients'].get('op')!.orders[ORDER_ID] = {
      view: 'full',
      alerts: true,
    };
    operator.gateway.server = {
      to: () => ({ emit: jest.fn() }),
      in: () => ({ fetchSockets: () => Promise.resolve([operator.client]) }),
    } as never;

    await operator.gateway['dispatch'](event);

    expect(emitOf(operator.client)).toHaveBeenCalledTimes(1);
  });
});

describe('TelemetryGateway radar (vista web)', () => {
  const asUser = (role: UserRole) =>
    ({ id: USER_ID, role, status: UserStatus.ACTIVE }) as unknown as User;

  it('el administrador entra a la sala del radar', async () => {
    const { gateway } = build(() => Promise.resolve(asUser(UserRole.ADMIN)));
    const client = socket();
    await gateway.handleConnection(client);
    const reply = await gateway.subscribeRadar(client);
    expect(
      (client as unknown as { join: jest.Mock }).join,
    ).toHaveBeenCalledWith('radar');
    expect(reply).toEqual({ event: 'subscribed-radar', data: {} });
  });

  it('el despachador no entra al radar', async () => {
    const { gateway } = build(() =>
      Promise.resolve(asUser(UserRole.DISPATCHER)),
    );
    const client = socket();
    await gateway.handleConnection(client);
    const reply = await gateway.subscribeRadar(client);
    expect(
      (client as unknown as { join: jest.Mock }).join,
    ).not.toHaveBeenCalled();
    expect(reply).toEqual({
      event: 'error',
      data: { message: 'Solo el administrador ve el radar.' },
    });
  });

  it('cada evento de vuelo se copia a la sala del radar', async () => {
    const { gateway } = build(() => Promise.resolve(asUser(UserRole.ADMIN)));
    const emit = jest.fn();
    const to = jest.fn().mockReturnValue({ emit });
    gateway.server = {
      to,
      in: () => ({ fetchSockets: () => Promise.resolve([]) }),
    } as never;

    await gateway['dispatch']({
      type: 'order-status',
      orderId: ORDER_ID,
      status: 'in_flight' as never,
    });

    expect(to).toHaveBeenCalledWith('radar');
    expect(emit).toHaveBeenCalledWith('radar-status', {
      orderId: ORDER_ID,
      status: 'in_flight',
    });
  });
});

describe('TelemetryGateway mapa de la flota del operador', () => {
  const HUB_ID = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const DRONE_ID = '33333333-3333-4333-8333-333333333333';

  const liveFlight = (leg: string, phase: string) => ({
    orderId: ORDER_ID,
    droneId: DRONE_ID,
    identifier: 'WG-198-001',
    latitude: 10.47,
    longitude: -73.25,
    altitudeM: 100,
    speedKmh: 98,
    batteryPercent: 71,
    payloadKg: 1.2,
    temperatureC: 5,
    latencyMs: 40,
    phase,
    leg,
    status: 'in_flight',
    etaSeconds: 60,
    progress: { secret: 'interno' },
  });

  /** Un gateway con un operador y un despachador en la sala de la central. */
  async function room() {
    const users: Record<string, User> = {
      op: {
        id: 'op',
        role: UserRole.FLEET_OPERATOR,
        status: UserStatus.ACTIVE,
        hubAssignments: [{ hubId: HUB_ID }],
      } as unknown as User,
      disp: {
        id: 'disp',
        role: UserRole.DISPATCHER,
        status: UserStatus.ACTIVE,
        hubAssignments: [{ hubId: HUB_ID }],
      } as unknown as User,
    };
    let next = 'op';
    const built = build(() => Promise.resolve(users[next]));
    const operator = socket(jest.fn(), 'op');
    const dispatcher = socket(jest.fn(), 'disp');
    await built.gateway.handleConnection(operator);
    await built.gateway.subscribeHub(operator, { hubId: HUB_ID });
    next = 'disp';
    await built.gateway.handleConnection(dispatcher);
    await built.gateway.subscribeHub(dispatcher, { hubId: HUB_ID });
    built.access.originHubOf.mockResolvedValue(HUB_ID);
    built.gateway.server = {
      to: () => ({ emit: jest.fn() }),
      in: (name: string) => ({
        fetchSockets: () =>
          Promise.resolve(
            name === `hub:${HUB_ID}` ? [operator, dispatcher] : [],
          ),
      }),
    } as never;
    const send = (event: object) => built.gateway['dispatch'](event as never);
    return { ...built, operator, dispatcher, send };
  }

  const cruise = () => ({
    type: 'telemetry',
    orderId: ORDER_ID,
    flight: liveFlight('outbound', 'cruise'),
  });

  it('el operador recibe cada vuelo de su central; el despachador no', async () => {
    const { operator, dispatcher, send } = await room();

    await send(cruise());

    expect(emitOf(operator)).toHaveBeenCalledWith(
      'hub-telemetry',
      expect.objectContaining({
        hubId: HUB_ID,
        orderId: ORDER_ID,
        altitudeM: 100,
        batteryPercent: 71,
        payloadKg: 1.2,
        latencyMs: 40,
      }),
    );
    expect(emitOf(dispatcher)).not.toHaveBeenCalled();
  });

  it('no manda el estado interno del reloj', async () => {
    const { operator, send } = await room();
    await send(cruise());
    const [, payload] = emitOf(operator).mock.calls[0] as [string, object];
    expect(payload).not.toHaveProperty('progress');
  });

  it('consulta la central del vuelo una sola vez, no en cada tick', async () => {
    const { access, send } = await room();
    await send(cruise());
    await send(cruise());
    await send(cruise());
    expect(access.originHubOf).toHaveBeenCalledTimes(1);
  });

  it('al aterrizar de regreso avisa que el vuelo terminó', async () => {
    const { operator, access, send } = await room();
    await send({
      type: 'telemetry',
      orderId: ORDER_ID,
      flight: liveFlight('return', 'landed'),
    });
    expect(emitOf(operator)).toHaveBeenCalledWith('hub-flight-ended', {
      hubId: HUB_ID,
      orderId: ORDER_ID,
      droneId: DRONE_ID,
    });
    // Ya no lo recuerda: un vuelo nuevo vuelve a consultar.
    await send(cruise());
    expect(access.originHubOf).toHaveBeenCalledTimes(2);
  });

  it('aterrizar en destino no termina el vuelo', async () => {
    const { operator, send } = await room();
    await send({
      type: 'telemetry',
      orderId: ORDER_ID,
      flight: liveFlight('outbound', 'landed'),
    });
    expect(emitOf(operator)).not.toHaveBeenCalledWith(
      'hub-flight-ended',
      expect.anything(),
    );
  });

  it('avisa los estados que mueven un dron', async () => {
    const { operator, dispatcher, send } = await room();
    await send({
      type: 'order-status',
      orderId: ORDER_ID,
      status: 'in_flight',
    });
    expect(emitOf(operator)).toHaveBeenCalledWith('hub-flight-status', {
      hubId: HUB_ID,
      orderId: ORDER_ID,
      status: 'in_flight',
    });
    expect(emitOf(dispatcher)).not.toHaveBeenCalled();
  });

  it('un pedido que nunca tuvo dron no llega al operador', async () => {
    const { operator, access, send } = await room();
    await send({ type: 'order-status', orderId: ORDER_ID, status: 'received' });
    expect(emitOf(operator)).not.toHaveBeenCalled();
    expect(access.originHubOf).not.toHaveBeenCalled();
  });

  it('si suelta el dron antes de despegar, avisa y deja de seguirlo', async () => {
    const { operator, access, send } = await room();
    const status = (value: string) => ({
      type: 'order-status',
      orderId: ORDER_ID,
      status: value,
    });
    await send(status('pending_load'));
    await send(status('reassigned'));
    expect(emitOf(operator)).toHaveBeenLastCalledWith('hub-flight-status', {
      hubId: HUB_ID,
      orderId: ORDER_ID,
      status: 'reassigned',
    });
    // Reasignado ya no le importa: no se vuelve a consultar ni a avisar.
    await send(status('reassigned'));
    expect(access.originHubOf).toHaveBeenCalledTimes(1);
    expect(emitOf(operator)).toHaveBeenCalledTimes(2);
  });

  it('si el mapa de la flota falla, quien sigue el pedido igual recibe', async () => {
    const { gateway, access, send } = await room();
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    access.originHubOf.mockRejectedValue(new Error('base caída'));
    const follower = socket(jest.fn(), 'follower');
    gateway['clients'].set('follower', {
      ready: Promise.resolve(null),
      orders: { [ORDER_ID]: { view: 'map', alerts: false } },
      hubs: {},
    });
    gateway.server = {
      to: () => ({ emit: jest.fn() }),
      in: (name: string) => ({
        fetchSockets: () =>
          Promise.resolve(name === `order:${ORDER_ID}` ? [follower] : []),
      }),
    } as never;

    await send(cruise());

    expect(emitOf(follower)).toHaveBeenCalledWith(
      'telemetry',
      expect.objectContaining({ orderId: ORDER_ID }),
    );
    expect(warn).toHaveBeenCalled();
    warn.mockRestore();
  });
});

function emitOf(client: Socket) {
  return (client as unknown as { emit: jest.Mock }).emit;
}
