import { Logger, OnModuleInit } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtPayload } from '../auth/jwt-payload';
import { UserStatus } from '../common/enums/user-status.enum';
import { User } from '../users/user.entity';
import { TelemetryAccessService } from './telemetry-access.service';
import { TelemetryEvent, TelemetryPublisher } from './telemetry.publisher';
import { TelemetryAccess, presentTelemetry } from './telemetry.rules';

const UUID_V4 =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type ClientState = {
  user?: User;
  orders: Record<string, TelemetryAccess>;
};

@WebSocketGateway({
  namespace: '/telemetry',
  cors: { origin: true },
})
export class TelemetryGateway
  implements OnGatewayConnection, OnGatewayDisconnect, OnModuleInit
{
  private readonly logger = new Logger(TelemetryGateway.name);
  private readonly clients = new Map<string, ClientState>();

  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly access: TelemetryAccessService,
    private readonly publisher: TelemetryPublisher,
  ) {}

  onModuleInit(): void {
    this.publisher.onEvent((event) => {
      void this.dispatch(event);
    });
  }

  async handleConnection(client: Socket): Promise<void> {
    const state: ClientState = { orders: {} };
    this.clients.set(client.id, state);
    const token = tokenFrom(client);
    if (!token) {
      client.disconnect(true);
      return;
    }
    try {
      const payload = this.jwt.verify<JwtPayload>(token);
      const user = await this.access.findUser(payload.sub);
      if (!user || user.status !== UserStatus.ACTIVE) {
        client.disconnect(true);
        return;
      }
      state.user = user;
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    this.clients.delete(client.id);
  }

  @SubscribeMessage('subscribe')
  async subscribe(client: Socket, body: { orderId?: string }) {
    const orderId = body?.orderId ?? '';
    const state = this.clients.get(client.id);
    const user = state?.user;
    if (!user || !UUID_V4.test(orderId)) {
      return { event: 'error', data: { message: 'El pedido no existe.' } };
    }
    const access = await this.access.resolve(user, orderId);
    if (!access) {
      return { event: 'error', data: { message: 'El pedido no existe.' } };
    }
    state.orders[orderId] = access;
    await client.join(room(orderId));
    const flight = await this.publisher.readFlight(orderId);
    if (flight) {
      client.emit('telemetry', presentTelemetry(flight, access.view));
    }
    return { event: 'subscribed', data: { orderId } };
  }

  private async dispatch(event: TelemetryEvent): Promise<void> {
    try {
      if (event.type === 'telemetry') {
        await this.emit(event.orderId, 'telemetry', (access) =>
          presentTelemetry(event.flight, access.view),
        );
        return;
      }
      if (event.type === 'order-status') {
        await this.emit(event.orderId, 'order-status', () => ({
          orderId: event.orderId,
          status: event.status,
        }));
        return;
      }
      await this.emit(event.orderId, 'alert', (access) =>
        access.alerts
          ? {
              orderId: event.orderId,
              droneId: event.droneId,
              kind: event.kind,
              message: event.message,
            }
          : null,
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : 'socket';
      this.logger.error(`No se pudo publicar telemetría: ${message}`);
    }
  }

  private async emit(
    orderId: string,
    event: string,
    payloadFor: (access: TelemetryAccess) => object | null,
  ): Promise<void> {
    if (!this.server) {
      return;
    }
    const sockets = await this.server.in(room(orderId)).fetchSockets();
    for (const socket of sockets) {
      const access = this.clients.get(socket.id)?.orders[orderId];
      if (!access) {
        continue;
      }
      const payload = payloadFor(access);
      if (payload) {
        socket.emit(event, payload);
      }
    }
  }
}

function tokenFrom(client: Socket): string | null {
  const auth: unknown = client.handshake.auth;
  if (typeof auth !== 'object' || auth === null || !('token' in auth)) {
    return null;
  }
  const token = auth.token;
  return typeof token === 'string' && token ? token : null;
}

function room(orderId: string): string {
  return `order:${orderId}`;
}
