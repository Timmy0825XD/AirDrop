import { Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { RouteLeg } from '../common/enums/route-leg.enum';
import { GeoJsonPolygon } from '../geofences/geofences.rules';
import { LngLat, PlannedCorridor, planOutboundCorridor } from './routing.rules';

type RouteRow = {
  orderId: string;
  altitudeM: number | string;
  distanceKm: number | string;
  path: string;
};

@Injectable()
export class RoutePlannerService {
  constructor(private readonly dataSource: DataSource) {}

  plan(
    origin: LngLat,
    destination: LngLat,
    geofences: GeoJsonPolygon[],
  ): PlannedCorridor | null {
    return planOutboundCorridor(origin, destination, geofences);
  }

  async loadPolygons(manager: EntityManager): Promise<GeoJsonPolygon[]> {
    const rows: Array<{ polygon: string }> = await manager.query(
      `SELECT ST_AsGeoJSON(polygon) AS polygon FROM geofences`,
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

  async deleteOutbound(orderId: string, manager: EntityManager): Promise<void> {
    await manager.query(
      `DELETE FROM mission_routes WHERE "orderId" = $1 AND leg = $2`,
      [orderId, RouteLeg.OUTBOUND],
    );
  }

  findOutboundMany(orderIds: string[]): Promise<Map<string, PlannedCorridor>> {
    return this.findLegMany(orderIds, RouteLeg.OUTBOUND);
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
