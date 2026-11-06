import { Injectable, OnModuleInit } from '@nestjs/common';
import { HubOutageService } from '../hubs/hub-outage.service';
import { DecisionService } from './decision.service';
import { EmergencyDispatchService } from './emergency-dispatch.service';

/**
 * RF-36 y CU-45: cuando una central se queda sin energía, sus urgencias pasan
 * a la siguiente central como si hubiera declinado y lo que tenía por cargar
 * sale de su cola. Los drones que vuelven a ella aterrizan igual.
 */
@Injectable()
export class HubOutageRelocationService implements OnModuleInit {
  constructor(
    private readonly outages: HubOutageService,
    private readonly decision: DecisionService,
    private readonly dispatch: EmergencyDispatchService,
  ) {}

  onModuleInit(): void {
    this.outages.onOutageStarted((hubId) => this.relocate(hubId));
  }

  async relocate(hubId: string): Promise<void> {
    await this.dispatch.withdrawHub(hubId);
    const toOffer = await this.decision.evacuateHub(hubId);
    for (const orderId of toOffer) {
      // La oferta nueva ya no incluye a la central sin energía.
      await this.dispatch.start(orderId);
    }
  }
}
