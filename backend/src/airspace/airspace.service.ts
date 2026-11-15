import { BadRequestException, Injectable } from '@nestjs/common';
import { AirspaceZoneKind } from '../common/enums/airspace-zone-kind.enum';
import { HubNetworkRole } from '../common/enums/hub-network-role.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat } from '../routing/routing.rules';
import {
  AirspaceZone,
  HUB_IN_PROHIBITED_AIRSPACE,
  NODE_IN_RESTRICTED_AIRSPACE,
  blockingPolygons,
  coordinatedZones,
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
  private readonly coordinated: AirspaceZone[] = coordinatedZones(this.zones);

  all(): AirspaceZone[] {
    return this.zones;
  }

  /** Lo que ningún corredor cruza (sin las zonas coordinadas). */
  blockingPolygons(): GeoJsonPolygon[] {
    return this.blocking;
  }

  coordinatedZones(): AirspaceZone[] {
    return this.coordinated;
  }

  /** La zona bloqueante o coordinada que contiene el punto, si hay una. */
  restrictionAt(point: LngLat): AirspaceZone | null {
    return zoneAt(
      point,
      this.zones.filter(
        (zone) =>
          isBlocking(zone) || zone.kind === AirspaceZoneKind.COORDINATED,
      ),
    );
  }

  /** La zona de alguno de esos tipos que contiene el punto (RU-02: la ciudad). */
  zoneOfKindAt(point: LngLat, kinds: AirspaceZoneKind[]): AirspaceZone | null {
    return zoneAt(
      point,
      this.zones.filter((zone) => kinds.includes(zone.kind)),
    );
  }

  /**
   * RF-06 y RF-07: un nodo no queda en zona urbana, en el anillo de un
   * aeródromo, en una zona prohibida ni en una coordinada. Una ESE puede
   * estar en una coordinada (es el sitio pactado), no en una bloqueante.
   */
  assertHubLocation(role: HubNetworkRole, point: LngLat): void {
    const zone = this.restrictionAt(point);
    if (!zone) {
      return;
    }
    if (role === HubNetworkRole.NODE) {
      throw new BadRequestException(
        `${NODE_IN_RESTRICTED_AIRSPACE} (${zone.name})`,
      );
    }
    if (isBlocking(zone)) {
      throw new BadRequestException(
        `${HUB_IN_PROHIBITED_AIRSPACE} (${zone.name})`,
      );
    }
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
      gateway: zone.gateway,
      sites: zone.sites,
    }));
  }
}
