import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../common/enums/order-status.enum';
import type { IncidentJson } from '../simulation/flight-incidents.service';
import { FlightAlertKind } from '../simulation/simulation.rules';
import {
  TelemetryEvent,
  TelemetryPublisher,
} from '../telemetry/telemetry.publisher';

const ALERT_MESSAGES: Record<FlightAlertKind, string> = {
  battery_critical: 'Batería crítica en el dron en vuelo.',
  failure: 'Falla de batería en el dron en vuelo.',
  cold_chain: 'La temperatura de la carga salió del rango de 2 a 8 °C.',
  wind_limit:
    'El viento donde va el dron pasa del límite del Wingcopter (15 m/s, ráfagas de 20 m/s).',
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

  /** RF-33: la ruta cambió en vuelo, o no hay una segura. */
  rerouted(
    event: Omit<Extract<TelemetryEvent, { type: 'rerouted' }>, 'type'>,
  ): Promise<void> {
    return this.telemetry.publish({ type: 'rerouted', ...event });
  }

  /** RF-34 y CU-32: el incidente, su protocolo y en qué va. */
  incident(incident: IncidentJson): Promise<void> {
    return this.telemetry.publish({ type: 'incident', incident });
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
