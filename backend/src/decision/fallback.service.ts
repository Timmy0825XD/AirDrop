import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { FallbackKind } from '../common/enums/fallback-kind.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { Hub } from '../hubs/hub.entity';
import { FallbackOption, Order } from '../orders/order.entity';
import {
  applyConventional,
  applyHubReassignment,
  applyRetry,
  canReassign,
  droneSearchExclusions,
  rankHubsByDistance,
  scheduledRetryMs,
  shouldRetry,
} from './fallback.rules';
import { HubEvaluationService } from './hub-evaluation.service';

type Alternatives = {
  hub: FallbackOption | null;
  withStock: FallbackOption[];
};

/**
 * RF-18 y CU-31: cuando ningún dron de la central puede salir, decide la
 * alternativa y la deja en el pedido. No reserva dron: la central sugerida
 * autoriza como siempre.
 */
@Injectable()
export class FallbackService {
  constructor(private readonly hubs: HubEvaluationService) {}

  async resolve(
    manager: EntityManager,
    order: Order,
    failingHub: Hub,
    today: string,
    polygons: GeoJsonPolygon[],
    now: Date,
  ): Promise<FallbackKind> {
    const retryMs = scheduledRetryMs();
    const nextRetryAt = new Date(now.getTime() + retryMs);
    if (shouldRetry(order, now, nextRetryAt)) {
      applyRetry(order, failingHub.id, nextRetryAt, retryMs);
    } else {
      const found = await this.alternatives(
        manager,
        order,
        failingHub.id,
        today,
        polygons,
      );
      if (found.hub) {
        applyHubReassignment(order, failingHub.id, found.hub, now);
      } else {
        applyConventional(order, failingHub.id, found.withStock, now);
      }
    }
    await manager.save(order);
    return order.fallbackKind as FallbackKind;
  }

  /**
   * Recorre las centrales activas de la más cercana al destino a la más
   * lejana. Gana la primera con lote, corredor y dron elegible. De paso
   * guarda las que tienen el insumo, para el traslado convencional.
   */
  private async alternatives(
    manager: EntityManager,
    order: Order,
    failingHubId: string,
    today: string,
    polygons: GeoJsonPolygon[],
  ): Promise<Alternatives> {
    const active = await manager.find(Hub, {
      where: { status: HubStatus.ACTIVE },
    });
    const ranked = rankHubsByDistance(
      active.filter((hub) => hub.id !== order.destinationHubId),
      {
        longitude: order.longitude as number,
        latitude: order.latitude as number,
      },
    );
    const skipDrones = droneSearchExclusions(order, failingHubId);
    const reassignable = canReassign(order);
    const withStock: FallbackOption[] = [];
    for (const { hub, distanceKm } of ranked) {
      const option = toOption(hub, distanceKm);
      if (reassignable && !skipDrones.has(hub.id)) {
        const evaluation = await this.hubs.evaluate(
          manager,
          hub,
          order,
          today,
          polygons,
          false,
        );
        if (evaluation.lot && evaluation.corridor && evaluation.choice.chosen) {
          return { hub: option, withStock };
        }
        if (evaluation.lot) {
          withStock.push(option);
        }
        continue;
      }
      if (await this.hubs.findFefoLot(manager, hub.id, order, today, false)) {
        withStock.push(option);
      }
    }
    return { hub: null, withStock };
  }
}

function toOption(hub: Hub, distanceKm: number): FallbackOption {
  return {
    hubId: hub.id,
    name: hub.name,
    address: hub.address,
    contactPhone: hub.contactPhone,
    contactEmail: hub.contactEmail,
    distanceKm,
  };
}
