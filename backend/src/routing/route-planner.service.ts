import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { simClock } from '../common/clock/sim-clock';
import {
  GeoJsonPolygon,
  activeGeofenceSql,
} from '../geofences/geofences.rules';
import { WeatherService } from '../weather/weather.service';
import { AirspaceService } from '../airspace/airspace.service';
import {
  DESTINATION_IN_GEOFENCE,
  LngLat,
  PlannedCorridor,
  isInsideGeofence,
  planCorridor,
  planReturnCorridor,
} from './routing.rules';

type RouteRow = {
  orderId: string;
  altitudeM: number | string;
  distanceKm: number | string;
  path: string;
};

@Injectable()
export class RoutePlannerService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly weather: WeatherService,
    private readonly airspace: AirspaceService,
  ) {}

  /**
   * RF-12: el corredor de ida. `loadPolygons` ya trae las zonas legales:
   * aquí solo se busca el camino.
   */
  plan(
    origin: LngLat,
    destination: LngLat,
    obstacles: GeoJsonPolygon[],
  ): PlannedCorridor | null {
    return planCorridor(origin, destination, obstacles);
  }

  /** Regreso con las zonas vigentes; ver `planReturnCorridor`. */
  planReturn(
    from: LngLat,
    hub: LngLat,
    obstacles: GeoJsonPolygon[],
    outbound: PlannedCorridor | null,
  ): ReturnType<typeof planReturnCorridor> {
    return planReturnCorridor(from, hub, obstacles, outbound);
  }

  /** Un destino dentro de una geovalla o de una zona legal no tiene corredor. */
  async assertDestinationAllowed(
    destination: LngLat,
    manager: EntityManager = this.dataSource.manager,
  ): Promise<void> {
    // Solo geovallas y zonas: una tormenta pasa, el punto sigue valiendo.
    const polygons = [
      ...(await this.loadGeofences(manager)),
      ...this.airspace.blockingPolygons(),
    ];
    if (isInsideGeofence(destination, polygons)) {
      throw new BadRequestException(DESTINATION_IN_GEOFENCE);
    }
  }

  /**
   * RF-12, RF-32 y RF-43: lo que una ruta no puede cruzar: geovallas,
   * tormentas vigentes y zonas legales.
   */
  async loadPolygons(manager: EntityManager): Promise<GeoJsonPolygon[]> {
    return [
      ...(await this.loadGeofences(manager)),
      ...this.weather.stormPolygons(),
      ...this.airspace.blockingPolygons(),
    ];
  }

  /** Las del operador y las temporales que no han vencido (RF-36). */
  async loadGeofences(manager: EntityManager): Promise<GeoJsonPolygon[]> {
    const rows: Array<{ polygon: string }> = await manager.query(
      `SELECT ST_AsGeoJSON(polygon) AS polygon FROM geofences
       WHERE ${activeGeofenceSql('$1')}`,
      [simClock.now()],
    );
    return rows.map((row) => JSON.parse(row.polygon) as GeoJsonPolygon);
  }

  saveOutbound(
    orderId: string,
    corridor: PlannedCorridor,
    manager: EntityManager,
  ): Promise<void> {
    return this.saveLeg(orderId, RouteLeg.OUTBOUND, corridor, manager);
  }

  saveReturn(
    orderId: string,
    corridor: PlannedCorridor,
    manager: EntityManager,
  ): Promise<void> {
    return this.saveLeg(orderId, RouteLeg.RETURN, corridor, manager);
  }

  private async saveLeg(
    orderId: string,
    leg: RouteLeg,
    corridor: PlannedCorridor,
    manager: EntityManager,
  ): Promise<void> {
    const path = JSON.stringify({
      type: 'LineString',
      coordinates: corridor.coordinates,
    });
    await manager.query(
      `INSERT INTO mission_routes (id, "orderId", leg, "altitudeM", "distanceKm", path)
       VALUES (
         gen_random_uuid(),
         $1,
         $2,
         $3,
         $4,
         ST_SetSRID(ST_GeomFromGeoJSON($5), 4326)
       )`,
      [orderId, leg, corridor.altitudeM, corridor.distanceKm, path],
    );
  }

  /**
   * RF-33: el corredor cambió en vuelo. El de antes queda en `previousPath`
   * para que la consola lo muestre punteado.
   */
  async replaceLeg(
    orderId: string,
    leg: RouteLeg,
    corridor: PlannedCorridor,
    manager: EntityManager = this.dataSource.manager,
  ): Promise<void> {
    const path = JSON.stringify({
      type: 'LineString',
      coordinates: corridor.coordinates,
    });
    await manager.query(
      `UPDATE mission_routes
       SET "previousPath" = path,
           path = ST_SetSRID(ST_GeomFromGeoJSON($3), 4326),
           "distanceKm" = $4
       WHERE "orderId" = $1 AND leg = $2`,
      [orderId, leg, path, corridor.distanceKm],
    );
  }

  /** Los corredores de antes de cambiar la ruta, por tramo. */
  async findPrevious(
    orderId: string,
  ): Promise<Partial<Record<RouteLeg, Array<[number, number]>>>> {
    const rows: Array<{ leg: RouteLeg; path: string }> =
      await this.dataSource.query(
        `SELECT leg, ST_AsGeoJSON("previousPath") AS path
         FROM mission_routes
         WHERE "orderId" = $1 AND "previousPath" IS NOT NULL`,
        [orderId],
      );
    const previous: Partial<Record<RouteLeg, Array<[number, number]>>> = {};
    for (const row of rows) {
      previous[row.leg] = (
        JSON.parse(row.path) as { coordinates: Array<[number, number]> }
      ).coordinates;
    }
    return previous;
  }

  /** RF-35: el pedido vuelve a despacharse; el dron nuevo tendrá su corredor. */
  async deleteLegs(orderId: string, manager: EntityManager): Promise<void> {
    await manager.query(`DELETE FROM mission_routes WHERE "orderId" = $1`, [
      orderId,
    ]);
  }

  async deleteOutbound(orderId: string, manager: EntityManager): Promise<void> {
    await manager.query(
      `DELETE FROM mission_routes WHERE "orderId" = $1 AND leg = $2`,
      [orderId, RouteLeg.OUTBOUND],
    );
  }

  findOutboundMany(orderIds: string[]): Promise<Map<string, PlannedCorridor>> {
    return this.findLegMany(orderIds, RouteLeg.OUTBOUND);
  }

  /** Regresos ya planificados (el reloj los guarda al iniciar el regreso). */
  findReturnMany(orderIds: string[]): Promise<Map<string, PlannedCorridor>> {
    return this.findLegMany(orderIds, RouteLeg.RETURN);
  }

  async findReturn(orderId: string): Promise<PlannedCorridor | null> {
    const routes = await this.findLegMany([orderId], RouteLeg.RETURN);
    return routes.get(orderId) ?? null;
  }

  private async findLegMany(
    orderIds: string[],
    leg: RouteLeg,
  ): Promise<Map<string, PlannedCorridor>> {
    const routes = new Map<string, PlannedCorridor>();
    if (!orderIds.length) {
      return routes;
    }
    const rows: RouteRow[] = await this.dataSource.query(
      `SELECT "orderId",
              "altitudeM"::float8 AS "altitudeM",
              "distanceKm"::float8 AS "distanceKm",
              ST_AsGeoJSON(path) AS path
       FROM mission_routes
       WHERE "orderId" = ANY($1::uuid[]) AND leg = $2`,
      [orderIds, leg],
    );
    for (const row of rows) {
      const parsed = JSON.parse(row.path) as {
        coordinates: Array<[number, number]>;
      };
      routes.set(row.orderId, {
        altitudeM: Number(row.altitudeM),
        distanceKm: Number(row.distanceKm),
        coordinates: parsed.coordinates,
      });
    }
    return routes;
  }
}
