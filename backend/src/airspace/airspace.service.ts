import { BadRequestException, Injectable } from '@nestjs/common';
import { HubNetworkRole } from '../common/enums/hub-network-role.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat } from '../routing/routing.rules';
import {
  AirspaceZone,
  HUB_IN_PROHIBITED_AIRSPACE,
  NODE_IN_RESTRICTED_AIRSPACE,
  blockingPolygons,
  isBlocking,
  zoneAt,
} from './airspace.rules';
import { regionalAirspace } from './regional-airspace';

/**
 * RF-43: las zonas legales vienen con el escenario y no se editan desde la
 * app (son la norma, no una decisión de la central). Viven en memoria: el
 * planificador las consulta en cada ruta sin ir a la base.
 */
@Injectable()
export class AirspaceService {
  private readonly zones: AirspaceZone[] = regionalAirspace();
  private readonly blocking: GeoJsonPolygon[] = blockingPolygons(this.zones);

  all(): AirspaceZone[] {
    return this.zones;
  }

  /** Lo que ningún corredor cruza. */
  blockingPolygons(): GeoJsonPolygon[] {
    return this.blocking;
  }

  /** La zona que contiene el punto, si hay una. */
  restrictionAt(point: LngLat): AirspaceZone | null {
    return zoneAt(point, this.zones.filter(isBlocking));
  }

  /**
   * RF-06 y RF-07: ninguna central queda dentro de una zona legal. Un nodo
   * despega desde ahí; una ESE recibe vuelos.
   */
  assertHubLocation(role: HubNetworkRole, point: LngLat): void {
    const zone = this.restrictionAt(point);
    if (!zone) {
      return;
    }
    const message =
      role === HubNetworkRole.NODE
        ? NODE_IN_RESTRICTED_AIRSPACE
        : HUB_IN_PROHIBITED_AIRSPACE;
    throw new BadRequestException(`${message} (${zone.name})`);
  }

  /** Para el mapa: cada zona con su regla y su fuente. */
  view() {
    return this.zones.map((zone) => ({
      code: zone.code,
      kind: zone.kind,
      name: zone.name,
      legalBasis: zone.legalBasis,
      source: zone.source,
      blocking: isBlocking(zone),
      polygon: zone.polygon,
    }));
  }
}
