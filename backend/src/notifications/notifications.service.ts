import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../common/enums/order-status.enum';
import { FlightAlertKind } from '../simulation/simulation.rules';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';

const ALERT_MESSAGES: Record<FlightAlertKind, string> = {
  battery_critical: 'Batería crítica en el dron en vuelo.',
  failure: 'Falla de batería en el dron en vuelo.',
};

@Injectable()
export class NotificationsService {
  constructor(private readonly telemetry: TelemetryPublisher) {}

  statusChanged(orderId: string, status: OrderStatus): Promise<void> {
    return this.telemetry.publish({ type: 'order-status', orderId, status });
  }

  /** La cola de una central cambió (p. ej. le llegó un pedido reasignado). */
  queueChanged(hubId: string, orderId: string): Promise<void> {
    return this.telemetry.publish({ type: 'queue-changed', hubId, orderId });
  }

  alert(
    orderId: string,
    droneId: string,
    kind: FlightAlertKind,
  ): Promise<void> {
    return this.telemetry.publish({
      type: 'alert',
      orderId,
      droneId,
      kind,
      message: ALERT_MESSAGES[kind],
    });
  }
}
