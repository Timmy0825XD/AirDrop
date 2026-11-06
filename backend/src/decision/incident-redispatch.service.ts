import { Injectable, OnModuleInit } from '@nestjs/common';
import { FlightClockService } from '../simulation/flight-clock.service';
import { DecisionService } from './decision.service';
import { EmergencyDispatchService } from './emergency-dispatch.service';

/**
 * RF-35 y CU-44: cuando el reloj de vuelo avisa que una misión no llegó por
 * un incidente, el pedido vuelve al motor de decisión. La urgencia a una
 * persona se ofrece otra vez a las centrales, con prioridad de emergencia.
 */
@Injectable()
export class IncidentRedispatchService implements OnModuleInit {
  constructor(
    private readonly flights: FlightClockService,
    private readonly decision: DecisionService,
    private readonly dispatch: EmergencyDispatchService,
  ) {}

  onModuleInit(): void {
    this.flights.onMissionAborted((orderId) => this.redispatch(orderId));
  }

  async redispatch(orderId: string): Promise<void> {
    const path = await this.decision.redispatchAfterIncident(orderId);
    if (path === 'offers') {
      await this.dispatch.start(orderId);
    }
  }
}
