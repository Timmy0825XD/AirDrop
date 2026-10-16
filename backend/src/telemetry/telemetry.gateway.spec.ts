import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
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
  };
  const publisher = { readFlight: jest.fn().mockResolvedValue(null) };
  const gateway = new TelemetryGateway(
    jwt as unknown as JwtService,
    access as unknown as TelemetryAccessService,
    publisher as unknown as TelemetryPublisher,
  );
  return { gateway, access };
}

function socket(disconnect = jest.fn()) {
  return {
    id: 'socket-1',
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
